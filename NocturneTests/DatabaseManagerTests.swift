import XCTest
import GRDB
@testable import Nocturne

final class DatabaseManagerTests: XCTestCase {

    func testCreateAndMigrate() throws {
        let manager = try DatabaseManager.makeInMemory()

        try manager.dbQueue.read { db in
            let tables = try String.fetchAll(db, sql: """
                SELECT name FROM sqlite_master
                WHERE type = 'table'
                  AND name NOT LIKE 'sqlite_%'
                  AND name != 'grdb_migrations'
                ORDER BY name
                """)
            XCTAssertEqual(tables, ["measurements", "upload_queue"])
        }
    }

    func testInsertAndReadMeasurement() throws {
        let manager = try DatabaseManager.makeInMemory()

        let record = MeasurementRecord(
            id: "test-uuid-001",
            measuredAt: Date(timeIntervalSince1970: 1_700_000_000),
            latitude: 37.7749,
            longitude: -122.4194,
            altitudeM: 10.0,
            skyBrightness: 19.5,
            rawBrightness: 0.001,
            iphoneModel: "iPhone16,1",
            isoValue: 1600,
            exposureS: 4.0,
            calibrationVer: "1.0",
            cloudCoverPct: 25,
            isCloudy: false,
            isCalibrated: true,
            isUploaded: false,
            uploadedAt: nil,
            deviceTiltDeg: 5.2,
            bortleClass: 5
        )

        try manager.dbQueue.write { db in
            try record.insert(db)
        }

        let fetched = try manager.dbQueue.read { db in
            try MeasurementRecord.fetchOne(db, key: "test-uuid-001")
        }

        XCTAssertNotNil(fetched)
        guard let fetched else { return }

        XCTAssertEqual(fetched.id, "test-uuid-001")
        XCTAssertEqual(fetched.latitude, 37.7749, accuracy: 0.0001)
        XCTAssertEqual(fetched.longitude, -122.4194, accuracy: 0.0001)
        XCTAssertEqual(fetched.skyBrightness, 19.5, accuracy: 0.01)
        XCTAssertEqual(fetched.iphoneModel, "iPhone16,1")
        XCTAssertEqual(fetched.isoValue, 1600)
        XCTAssertEqual(fetched.exposureS, 4.0, accuracy: 0.01)
        XCTAssertEqual(fetched.cloudCoverPct, 25)
        XCTAssertFalse(fetched.isCloudy)
        XCTAssertTrue(fetched.isCalibrated)
        XCTAssertFalse(fetched.isUploaded)
        XCTAssertNil(fetched.uploadedAt)
        XCTAssertEqual(fetched.bortleClass, 5)
    }
}
