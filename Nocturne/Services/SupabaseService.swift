import Foundation
import GRDB
import Supabase
import os

actor SupabaseService {
    private let client: SupabaseClient
    private var tileCache: [String: (tiles: [HeatmapTile], fetchedAt: Date)] = [:]

    private let logger = Logger(subsystem: "com.nocturne.app", category: "SupabaseService")

    init() {
        guard let urlString = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String,
              let url = URL(string: urlString),
              let anonKey = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String,
              !urlString.contains("your-project") else {
            fatalError(
                "Supabase credentials not configured. "
                + "Copy Config.xcconfig.example to Config.xcconfig and add your credentials."
            )
        }
        self.client = SupabaseClient(supabaseURL: url, supabaseKey: anonKey)
    }

    /// For testing or when credentials are supplied at runtime (e.g. from AppState).
    init(url: URL, anonKey: String) {
        self.client = SupabaseClient(supabaseURL: url, supabaseKey: anonKey)
    }

    // MARK: - Upload with Retry

    /// Uploads a single measurement with exponential-backoff retry.
    /// On success, marks `is_uploaded = 1` and `uploaded_at = now()` in the local DB,
    /// then removes the record from `upload_queue`.
    func uploadMeasurement(_ record: MeasurementRecord, db: DatabaseQueue?) async throws {
        let payload = SupabaseMeasurement(from: record)

        var lastError: Error?
        for attempt in 0..<UploadConstants.maxRetryAttempts {
            do {
                try await client.from("measurements")
                    .insert(payload)
                    .execute()

                // Upload succeeded — persist status to local DB if available.
                if let db {
                    await markUploadedInDB(id: record.id, db: db)
                }
                logger.info("Uploaded measurement \(record.id) on attempt \(attempt + 1)")
                return
            } catch {
                lastError = error
                logger.warning(
                    "Upload attempt \(attempt + 1) failed for \(record.id): \(error.localizedDescription)"
                )
                let delaySec = pow(2.0, Double(attempt)) // 1s, 2s, 4s
                try? await Task.sleep(for: .seconds(delaySec))
            }
        }
        logger.error("All \(UploadConstants.maxRetryAttempts) upload attempts failed for \(record.id)")
        throw lastError!
    }

    // MARK: - Retry Pending Uploads

    /// Reads all unuploaded measurements present in `upload_queue` and attempts to upload each.
    /// Failed individual records are logged and skipped so a single bad record can't block the batch.
    func retryPendingUploads(db: DatabaseQueue) async {
        do {
            let pending: [MeasurementRecord] = try await db.read { dbConn in
                try MeasurementRecord
                    .joining(required: MeasurementRecord.hasOne(
                        UploadQueueRecord.self,
                        using: ForeignKey(["id"], to: ["measurement_id"])
                    ))
                    .filter(Column("is_uploaded") == 0)
                    .fetchAll(dbConn)
            }

            guard !pending.isEmpty else {
                logger.debug("No pending uploads in queue")
                return
            }

            logger.info("Retrying \(pending.count) pending upload(s)")

            for record in pending {
                do {
                    try await uploadMeasurement(record, db: db)
                } catch {
                    logger.error(
                        "Failed to upload measurement \(record.id) after retries: \(error.localizedDescription)"
                    )
                }
            }
        } catch {
            logger.error("Failed to read pending uploads from DB: \(error.localizedDescription)")
        }
    }

    // MARK: - Heatmap Tiles (Cached)

    func fetchHeatmapTiles(
        minLat: Double, maxLat: Double,
        minLon: Double, maxLon: Double,
        gridSize: Double = MapConstants.tileGridSizeDegrees
    ) async throws -> [HeatmapTile] {
        let cacheKey = cacheKey(minLat: minLat, maxLat: maxLat, minLon: minLon, maxLon: maxLon)

        if let entry = tileCache[cacheKey] {
            let age = Date().timeIntervalSince(entry.fetchedAt)
            if age < MapConstants.tileCacheDurationSeconds {
                logger.debug("Returning cached heatmap tiles (age: \(Int(age))s)")
                return entry.tiles
            }
        }

        let response: [HeatmapTile] = try await client
            .rpc(
                "heatmap_tiles",
                params: [
                    "min_lat": minLat,
                    "max_lat": maxLat,
                    "min_lon": minLon,
                    "max_lon": maxLon,
                    "grid_size_deg": gridSize,
                ]
            )
            .execute()
            .value

        tileCache[cacheKey] = (tiles: response, fetchedAt: Date())
        logger.debug("Fetched \(response.count) heatmap tile(s) from Supabase")
        return response
    }

    // MARK: - Private Helpers

    private func cacheKey(minLat: Double, maxLat: Double, minLon: Double, maxLon: Double) -> String {
        "\(String(format: "%.2f", minLat)),\(String(format: "%.2f", maxLat)),"
        + "\(String(format: "%.2f", minLon)),\(String(format: "%.2f", maxLon))"
    }

    private func markUploadedInDB(id: String, db: DatabaseQueue) async {
        do {
            let now = Int(Date().timeIntervalSince1970)
            try await db.write { dbConn in
                try dbConn.execute(
                    sql: "UPDATE measurements SET is_uploaded = 1, uploaded_at = ? WHERE id = ?",
                    arguments: [now, id]
                )
                try dbConn.execute(
                    sql: "DELETE FROM upload_queue WHERE measurement_id = ?",
                    arguments: [id]
                )
            }
            logger.debug("Marked measurement \(id) as uploaded in local DB")
        } catch {
            logger.error(
                "Failed to update upload status for \(id) in local DB: \(error.localizedDescription)"
            )
        }
    }
}

// MARK: - Upload Queue GRDB Record (join target)

private struct UploadQueueRecord: TableRecord {
    static let databaseTableName = "upload_queue"
}

// MARK: - Supabase Upload Payload

private struct SupabaseMeasurement: Encodable {
    let measuredAt: String
    let location: String            // WKT: "POINT(lon lat)"
    let altitudeM: Double
    let skyBrightness: Double
    let iphoneModel: String
    let calibrationVer: String
    let cloudCoverPct: Int?
    let isCloudy: Bool
    let isCalibrated: Bool
    let bortleClass: Int

    init(from record: MeasurementRecord) {
        let formatter = ISO8601DateFormatter()
        self.measuredAt = formatter.string(from: record.measuredAt)
        self.location = "POINT(\(record.longitude) \(record.latitude))"
        self.altitudeM = record.altitudeM
        self.skyBrightness = record.skyBrightness
        self.iphoneModel = record.iphoneModel
        self.calibrationVer = record.calibrationVer
        self.cloudCoverPct = record.cloudCoverPct
        self.isCloudy = record.isCloudy
        self.isCalibrated = record.isCalibrated
        self.bortleClass = record.bortleClass
    }

    enum CodingKeys: String, CodingKey {
        case measuredAt = "measured_at"
        case location
        case altitudeM = "altitude_m"
        case skyBrightness = "sky_brightness"
        case iphoneModel = "iphone_model"
        case calibrationVer = "calibration_ver"
        case cloudCoverPct = "cloud_cover_pct"
        case isCloudy = "is_cloudy"
        case isCalibrated = "is_calibrated"
        case bortleClass = "bortle_class"
    }
}
