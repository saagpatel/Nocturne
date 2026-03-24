import Foundation
import GRDB

struct MeasurementRecord: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let measuredAt: Date
    let latitude: Double
    let longitude: Double
    let altitudeM: Double
    let skyBrightness: Double       // mag/arcsec², calibrated
    let rawBrightness: Double       // cd/m²
    let iphoneModel: String         // e.g. "iPhone15,2"
    let isoValue: Int               // always 1600
    let exposureS: Double           // always 4.0
    let calibrationVer: String
    let cloudCoverPct: Int?
    let isCloudy: Bool
    let isCalibrated: Bool
    var isUploaded: Bool
    var uploadedAt: Date?
    let deviceTiltDeg: Double
    let bortleClass: Int            // 1–9
}

// MARK: - GRDB TableRecord

extension MeasurementRecord: TableRecord {
    static let databaseTableName = "measurements"
}

// MARK: - GRDB FetchableRecord

extension MeasurementRecord: FetchableRecord {
    init(row: Row) throws {
        id = row["id"]
        measuredAt = Date(timeIntervalSince1970: TimeInterval(row["measured_at"] as Int))
        latitude = row["latitude"]
        longitude = row["longitude"]
        altitudeM = row["altitude_m"]
        skyBrightness = row["sky_brightness"]
        rawBrightness = row["raw_brightness"]
        iphoneModel = row["iphone_model"]
        isoValue = row["iso_value"]
        exposureS = row["exposure_s"]
        calibrationVer = row["calibration_ver"]
        cloudCoverPct = row["cloud_cover_pct"]
        isCloudy = (row["is_cloudy"] as Int) != 0
        isCalibrated = (row["is_calibrated"] as Int) != 0
        isUploaded = (row["is_uploaded"] as Int) != 0
        uploadedAt = (row["uploaded_at"] as Int?).map {
            Date(timeIntervalSince1970: TimeInterval($0))
        }
        deviceTiltDeg = row["device_tilt_deg"]
        bortleClass = row["bortle_class"]
    }
}

// MARK: - GRDB PersistableRecord

extension MeasurementRecord: PersistableRecord {
    func encode(to container: inout PersistenceContainer) throws {
        container["id"] = id
        container["measured_at"] = Int(measuredAt.timeIntervalSince1970)
        container["latitude"] = latitude
        container["longitude"] = longitude
        container["altitude_m"] = altitudeM
        container["sky_brightness"] = skyBrightness
        container["raw_brightness"] = rawBrightness
        container["iphone_model"] = iphoneModel
        container["iso_value"] = isoValue
        container["exposure_s"] = exposureS
        container["calibration_ver"] = calibrationVer
        container["cloud_cover_pct"] = cloudCoverPct
        container["is_cloudy"] = isCloudy ? 1 : 0
        container["is_calibrated"] = isCalibrated ? 1 : 0
        container["is_uploaded"] = isUploaded ? 1 : 0
        container["uploaded_at"] = uploadedAt.map { Int($0.timeIntervalSince1970) }
        container["device_tilt_deg"] = deviceTiltDeg
        container["bortle_class"] = bortleClass
    }
}
