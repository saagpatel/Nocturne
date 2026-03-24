import XCTest
@testable import Nocturne

final class AstrometryTests: XCTestCase {

    // MARK: - Julian Date

    func testJulianDate_j2000Epoch() {
        // J2000.0 = January 1.5, 2000 TT ≈ January 1, 12:00 UTC 2000
        let components = DateComponents(
            calendar: .init(identifier: .gregorian),
            timeZone: .init(identifier: "UTC"),
            year: 2000, month: 1, day: 1, hour: 12, minute: 0, second: 0
        )
        let date = components.date!
        let jd = Astrometry.julianDate(from: date)
        XCTAssertEqual(jd, 2_451_545.0, accuracy: 0.001)
    }

    func testJulianDate_knownDate() {
        // July 4, 2024 00:00 UTC → JD ≈ 2460495.5
        let components = DateComponents(
            calendar: .init(identifier: .gregorian),
            timeZone: .init(identifier: "UTC"),
            year: 2024, month: 7, day: 4, hour: 0, minute: 0, second: 0
        )
        let date = components.date!
        let jd = Astrometry.julianDate(from: date)
        XCTAssertEqual(jd, 2_460_495.5, accuracy: 0.5)
    }

    // MARK: - GMST

    func testGMST_j2000() {
        // At J2000.0 epoch, GMST ≈ 280.46°
        let gmst = Astrometry.gmstDegrees(julianDate: 2_451_545.0)
        XCTAssertEqual(gmst, 280.46, accuracy: 1.0)
    }

    // MARK: - LST

    func testLST_greenwich() {
        // At Greenwich (lon=0), LST = GMST
        let components = DateComponents(
            calendar: .init(identifier: .gregorian),
            timeZone: .init(identifier: "UTC"),
            year: 2000, month: 1, day: 1, hour: 12, minute: 0
        )
        let date = components.date!
        let lst = Astrometry.localSiderealTime(longitude: 0, date: date)
        let gmst = Astrometry.gmstDegrees(julianDate: Astrometry.julianDate(from: date))
        XCTAssertEqual(lst, gmst, accuracy: 0.01)
    }

    func testLST_offset() {
        // At lon=-74° (New York), LST = GMST - 74
        let components = DateComponents(
            calendar: .init(identifier: .gregorian),
            timeZone: .init(identifier: "UTC"),
            year: 2000, month: 1, day: 1, hour: 12, minute: 0
        )
        let date = components.date!
        let lst = Astrometry.localSiderealTime(longitude: -74.0, date: date)
        let gmst = Astrometry.gmstDegrees(julianDate: Astrometry.julianDate(from: date))
        let expected = fmod(gmst - 74.0 + 360.0, 360.0)
        XCTAssertEqual(lst, expected, accuracy: 0.01)
    }

    // MARK: - Equatorial to Horizontal

    func testEquatorialToHorizontal_polaris() {
        // Polaris: RA ≈ 37.95°, Dec ≈ +89.26°
        // From latitude 40°N, Polaris altitude ≈ latitude ≈ 40° (always near the pole)
        // Actually Polaris altitude ≈ observer latitude, so ~40° at lat 40
        let components = DateComponents(
            calendar: .init(identifier: .gregorian),
            timeZone: .init(identifier: "UTC"),
            year: 2024, month: 6, day: 21, hour: 0, minute: 0
        )
        let date = components.date!
        let (altitude, _) = Astrometry.equatorialToHorizontal(
            ra: 37.95, dec: 89.26,
            latitude: 40.0, longitude: -74.0, date: date
        )
        // Polaris altitude should be close to observer latitude
        XCTAssertEqual(altitude, 40.0, accuracy: 5.0)
    }

    func testEquatorialToHorizontal_neverRises() {
        // Star at Dec -50° from latitude +40° never rises above horizon
        // (Dec + lat = -50 + 40 = -10, so max altitude ≈ -10°)
        let components = DateComponents(
            calendar: .init(identifier: .gregorian),
            timeZone: .init(identifier: "UTC"),
            year: 2024, month: 6, day: 21, hour: 12, minute: 0
        )
        let date = components.date!
        let (altitude, _) = Astrometry.equatorialToHorizontal(
            ra: 180.0, dec: -50.0,
            latitude: 40.0, longitude: -74.0, date: date
        )
        XCTAssertLessThan(altitude, 0.0)
    }

    // MARK: - Gnomonic Projection

    func testGnomonicProject_centerStar() {
        // Star exactly at projection center → (0, 0)
        let result = Astrometry.gnomonicProject(
            starRA: 180.0, starDec: 45.0,
            centerRA: 180.0, centerDec: 45.0
        )
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.x, 0.0, accuracy: 0.001)
        XCTAssertEqual(result!.y, 0.0, accuracy: 0.001)
    }

    func testGnomonicProject_offset10deg() {
        // Star 10° north of center
        let result = Astrometry.gnomonicProject(
            starRA: 180.0, starDec: 55.0,
            centerRA: 180.0, centerDec: 45.0
        )
        XCTAssertNotNil(result)
        // tan(10°) ≈ 0.176 radians
        let distance = sqrt(result!.x * result!.x + result!.y * result!.y)
        XCTAssertEqual(distance, 0.176, accuracy: 0.02)
    }

    func testGnomonicProject_behindObserver() {
        // Star 100° from center (>90°) → nil
        let result = Astrometry.gnomonicProject(
            starRA: 180.0, starDec: -55.0,
            centerRA: 180.0, centerDec: 45.0
        )
        XCTAssertNil(result)
    }

    // MARK: - Galactic to Equatorial

    func testGalacticToEquatorial_center() {
        // Galactic center (l=0, b=0) → RA ≈ 266.4°, Dec ≈ -29.0°
        let (ra, dec) = Astrometry.galacticToEquatorial(l: 0, b: 0)
        XCTAssertEqual(ra, 266.4, accuracy: 1.0)
        XCTAssertEqual(dec, -29.0, accuracy: 1.0)
    }
}
