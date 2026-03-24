import XCTest
@testable import Nocturne

final class CalibrationServiceTests: XCTestCase {

    func testCalibrationTableParsesFromJSON() throws {
        guard let url = Bundle.main.url(forResource: "calibration_table", withExtension: "json") else {
            XCTFail("calibration_table.json not found in test bundle")
            return
        }
        let data = try Data(contentsOf: url)
        let table = try JSONDecoder().decode(CalibrationTable.self, from: data)

        XCTAssertEqual(table.version, "1.0")
        XCTAssertGreaterThanOrEqual(table.coefficients.count, 12)

        for coeff in table.coefficients {
            XCTAssertFalse(coeff.iphoneModel.isEmpty)
            XCTAssertFalse(coeff.friendlyName.isEmpty)
            XCTAssertEqual(coeff.version, "1.0")
        }
    }

    func testAllExpectedModelsPresent() throws {
        guard let url = Bundle.main.url(forResource: "calibration_table", withExtension: "json") else {
            XCTFail("calibration_table.json not found in test bundle")
            return
        }
        let data = try Data(contentsOf: url)
        let table = try JSONDecoder().decode(CalibrationTable.self, from: data)
        let models = Set(table.coefficients.map(\.iphoneModel))

        let requiredModels = [
            "iPhone13,2",  // iPhone 12
            "iPhone14,2",  // iPhone 13 Pro
            "iPhone15,2",  // iPhone 14 Pro
            "iPhone16,1",  // iPhone 15 Pro
            "iPhone17,1",  // iPhone 16 Pro
        ]
        for model in requiredModels {
            XCTAssertTrue(models.contains(model), "Missing calibration for \(model)")
        }
    }
}
