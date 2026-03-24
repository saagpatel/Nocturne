import CoreLocation
import XCTest
@testable import Nocturne

final class ValidationGateTests: XCTestCase {

    private let gate = ValidationGate()

    // MARK: - Solar Altitude

    func testSolarAltitude_noonSF() {
        // Summer solstice, ~noon UTC in San Francisco (20:00 UTC is noon PDT)
        let components = DateComponents(
            calendar: .init(identifier: .gregorian),
            timeZone: .init(identifier: "UTC"),
            year: 2024, month: 6, day: 21, hour: 20, minute: 0
        )
        let date = components.date!
        let alt = ValidationGate.solarAltitude(latitude: 37.77, longitude: -122.41, date: date)
        // Sun should be high at local noon
        XCTAssertGreaterThan(alt, 50.0, "Expected solar altitude > 50° at noon, got \(alt)")
    }

    func testSolarAltitude_midnightSF() {
        // Summer solstice, midnight PDT = 07:00 UTC
        let components = DateComponents(
            calendar: .init(identifier: .gregorian),
            timeZone: .init(identifier: "UTC"),
            year: 2024, month: 6, day: 21, hour: 7, minute: 0
        )
        let date = components.date!
        let alt = ValidationGate.solarAltitude(latitude: 37.77, longitude: -122.41, date: date)
        XCTAssertLessThan(alt, -10.0, "Expected solar altitude < -10° at midnight, got \(alt)")
    }

    func testSolarAltitude_civilTwilightRange() {
        // At some point after sunset the sun passes through -6°.
        // March equinox, SF, ~02:00 UTC (6pm PDT) — sun should be near horizon
        let components = DateComponents(
            calendar: .init(identifier: .gregorian),
            timeZone: .init(identifier: "UTC"),
            year: 2024, month: 3, day: 20, hour: 2, minute: 30
        )
        let date = components.date!
        let alt = ValidationGate.solarAltitude(latitude: 37.77, longitude: -122.41, date: date)
        // Around sunset, altitude should be near 0° ± 10°
        XCTAssertGreaterThan(alt, -15.0)
        XCTAssertLessThan(alt, 15.0)
    }

    // MARK: - Tilt

    func testTiltFromZenith_upright() {
        // Phone face-up, level: gravity = (0, 0, -1)
        let tilt = ValidationGate.tiltFromZenith(gravityX: 0, gravityY: 0, gravityZ: -1)
        XCTAssertEqual(tilt, 0.0, accuracy: 0.1)
    }

    func testTiltFromZenith_tilted45() {
        // 45° tilt: gravity ≈ (0.707, 0, -0.707)
        let tilt = ValidationGate.tiltFromZenith(gravityX: 0.707, gravityY: 0, gravityZ: -0.707)
        XCTAssertEqual(tilt, 45.0, accuracy: 1.0)
    }

    func testTiltFromZenith_horizontal() {
        // Phone upright (portrait): gravity = (0, -1, 0)
        let tilt = ValidationGate.tiltFromZenith(gravityX: 0, gravityY: -1, gravityZ: 0)
        XCTAssertEqual(tilt, 90.0, accuracy: 1.0)
    }

    // MARK: - Validation Pipeline

    func testValidate_daytime_rejects() {
        // Noon in SF — should reject
        let components = DateComponents(
            calendar: .init(identifier: .gregorian),
            timeZone: .init(identifier: "UTC"),
            year: 2024, month: 6, day: 21, hour: 20, minute: 0
        )
        let context = makeContext(
            date: components.date!,
            latitude: 37.77,
            longitude: -122.41
        )
        let result = gate.validate(context: context)
        if case .rejected(.notDarkEnough) = result {
            // Expected
        } else {
            XCTFail("Expected .rejected(.notDarkEnough), got \(result)")
        }
    }

    func testValidate_excessiveTilt_rejects() {
        let context = makeContext(
            gravityX: 0.707, gravityY: 0, gravityZ: -0.707  // 45° tilt
        )
        let result = gate.validate(context: context)
        if case .rejected(.deviceTilt) = result {
            // Expected
        } else {
            XCTFail("Expected .rejected(.deviceTilt), got \(result)")
        }
    }

    func testValidate_brightPixels_rejects() {
        let context = makeContext(hotPixelFraction: 0.05)
        let result = gate.validate(context: context)
        if case .rejected(.lightSourceInFrame) = result {
            // Expected
        } else {
            XCTFail("Expected .rejected(.lightSourceInFrame), got \(result)")
        }
    }

    func testValidate_allPass_valid() {
        let context = makeContext(cloudCoverPct: 20)
        let result = gate.validate(context: context)
        if case .valid(let report) = result {
            XCTAssertFalse(report.isCloudy)
            XCTAssertEqual(report.cloudCoverPct, 20)
        } else {
            XCTFail("Expected .valid, got \(result)")
        }
    }

    func testValidate_cloudy_tagsButPasses() {
        let context = makeContext(cloudCoverPct: 80)
        let result = gate.validate(context: context)
        if case .valid(let report) = result {
            XCTAssertTrue(report.isCloudy)
        } else {
            XCTFail("Expected .valid with isCloudy, got \(result)")
        }
    }

    func testValidate_failFastOrder() {
        // Daytime AND tilted AND bright pixels — should fail on first gate (solar)
        let components = DateComponents(
            calendar: .init(identifier: .gregorian),
            timeZone: .init(identifier: "UTC"),
            year: 2024, month: 6, day: 21, hour: 20, minute: 0
        )
        let context = ValidationContext(
            location: CLLocation(latitude: 37.77, longitude: -122.41),
            date: components.date!,
            gravityX: 0.707, gravityY: 0, gravityZ: -0.707,  // tilted
            hotPixelFraction: 0.5,  // bright
            cloudCoverPct: nil
        )
        let result = gate.validate(context: context)
        if case .rejected(.notDarkEnough) = result {
            // Expected — first gate catches it
        } else {
            XCTFail("Expected .rejected(.notDarkEnough) (fail-fast), got \(result)")
        }
    }

    // MARK: - Helper

    /// Create a valid nighttime context with optional overrides.
    private func makeContext(
        date: Date? = nil,
        latitude: Double = 37.77,
        longitude: Double = -122.41,
        gravityX: Double = 0,
        gravityY: Double = 0,
        gravityZ: Double = -1,
        hotPixelFraction: Double = 0.001,
        cloudCoverPct: Int? = nil
    ) -> ValidationContext {
        // Default: midnight SF, winter (definitely dark)
        let defaultDate: Date = {
            let components = DateComponents(
                calendar: .init(identifier: .gregorian),
                timeZone: .init(identifier: "UTC"),
                year: 2024, month: 12, day: 21, hour: 8, minute: 0
            )
            return components.date!
        }()

        return ValidationContext(
            location: CLLocation(latitude: latitude, longitude: longitude),
            date: date ?? defaultDate,
            gravityX: gravityX,
            gravityY: gravityY,
            gravityZ: gravityZ,
            hotPixelFraction: hotPixelFraction,
            cloudCoverPct: cloudCoverPct
        )
    }
}
