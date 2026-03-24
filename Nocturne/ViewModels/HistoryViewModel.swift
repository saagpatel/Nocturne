import CoreLocation
import GRDB
import os

/// Loads past measurements from the local GRDB database and reverse-geocodes
/// each measurement's coordinates to a human-readable location name.
///
/// Geocoded names are cached in `geocodedNames` keyed by measurement ID,
/// so each location is only reverse-geocoded once per session.
@Observable
@MainActor
final class HistoryViewModel {

    // MARK: - Observable State

    private(set) var measurements: [MeasurementRecord] = []
    private(set) var geocodedNames: [String: String] = [:]  // id → city/region name
    private(set) var isLoading = false

    // MARK: - Private

    @ObservationIgnored
    private let db: DatabaseManager

    @ObservationIgnored
    private let geocoder = CLGeocoder()

    @ObservationIgnored
    private let logger = Logger(subsystem: "com.nocturne.app", category: "HistoryViewModel")

    // MARK: - Init

    init(db: DatabaseManager) {
        self.db = db
    }

    // MARK: - Load

    /// Fetches all measurements from the local database, sorted newest-first,
    /// then reverse-geocodes any not yet cached.
    func loadMeasurements() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let records: [MeasurementRecord] = try await db.dbQueue.read { database in
                try MeasurementRecord
                    .order(Column("measured_at").desc)
                    .fetchAll(database)
            }
            measurements = records

            // Geocode any record whose location name is not yet cached.
            for record in records where geocodedNames[record.id] == nil {
                await geocode(record)
            }
        } catch {
            logger.error("Failed to load measurements from local DB: \(error)")
        }
    }

    // MARK: - Accessors

    /// Returns the cached location name for a measurement, or a placeholder while geocoding.
    func locationName(for record: MeasurementRecord) -> String {
        geocodedNames[record.id] ?? "Locating…"
    }

    // MARK: - Private Geocoding

    private func geocode(_ record: MeasurementRecord) async {
        let location = CLLocation(latitude: record.latitude, longitude: record.longitude)
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            let name: String
            if let locality = placemarks.first?.locality {
                name = locality
            } else if let area = placemarks.first?.administrativeArea {
                name = area
            } else {
                name = coordinateFallback(for: record)
            }
            geocodedNames[record.id] = name
        } catch {
            // Geocoding can fail due to network unavailability or rate limiting; fall back gracefully.
            logger.debug("Reverse geocode failed for \(record.id): \(error.localizedDescription)")
            geocodedNames[record.id] = coordinateFallback(for: record)
        }
    }

    private func coordinateFallback(for record: MeasurementRecord) -> String {
        String(format: "%.2f°, %.2f°", record.latitude, record.longitude)
    }
}
