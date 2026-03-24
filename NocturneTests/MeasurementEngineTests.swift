import XCTest
@testable import Nocturne

final class MeasurementEngineTests: XCTestCase {

    func testPixelLuminanceToMagArcsec2() {
        // iPhone 16 Pro coefficients
        let calibration = CalibrationCoefficients(
            iphoneModel: "iPhone17,1",
            friendlyName: "iPhone 16 Pro",
            a: -2.58,
            b: 11.90,
            c: -0.002,
            version: "1.0"
        )

        let result = MeasurementEngine.pixelLuminanceToMagArcsec2(
            rawLuminance: 0.0005,
            calibration: calibration
        )

        // Expected: -2.58 * log10(0.0005) + 11.90 + (-0.002 * 25)
        //         = -2.58 * (-3.301) + 11.90 - 0.05
        //         = 8.516 + 11.85 ≈ 20.37
        XCTAssertGreaterThanOrEqual(result, 19.0)
        XCTAssertLessThanOrEqual(result, 21.0)
    }

    func testBortleClassification() {
        // Bortle thresholds: (1, 21.75), (2, 21.5), (3, 21.25), (4, 20.5),
        //                    (5, 19.5), (6, 18.5), (7, 17.5), (8, 16.5), (9, 0.0)
        XCTAssertEqual(MeasurementEngine.bortleClass(from: 21.5), 2)
        XCTAssertEqual(MeasurementEngine.bortleClass(from: 22.0), 1)
        XCTAssertEqual(MeasurementEngine.bortleClass(from: 19.5), 5)

        // 17.0 < 17.5 (Bortle 7 floor), so it falls to Bortle 8 (16.5 floor)
        XCTAssertEqual(MeasurementEngine.bortleClass(from: 17.0), 8)
    }

    func testBortleBoundaryValues() {
        // Exactly at Bortle 1 threshold
        XCTAssertEqual(MeasurementEngine.bortleClass(from: 21.75), 1)

        // Just below Bortle 1 threshold → Bortle 2
        XCTAssertEqual(MeasurementEngine.bortleClass(from: 21.74), 2)

        // Minimum possible: Bortle 9
        XCTAssertEqual(MeasurementEngine.bortleClass(from: 0.0), 9)

        // Very bright urban sky
        XCTAssertEqual(MeasurementEngine.bortleClass(from: 16.0), 9)

        // Zero luminance → returns urbanMinMagArcsec2 (16.0) → Bortle 9
        let zeroResult = MeasurementEngine.pixelLuminanceToMagArcsec2(
            rawLuminance: 0.0,
            calibration: CalibrationCoefficients(
                iphoneModel: "test", friendlyName: "test",
                a: -2.5, b: 11.5, c: -0.003, version: "1.0"
            )
        )
        XCTAssertEqual(zeroResult, SkyBrightnessConstants.urbanMinMagArcsec2)
    }
}
