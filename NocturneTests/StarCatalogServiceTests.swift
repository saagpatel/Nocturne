import GRDB
import XCTest
@testable import Nocturne

final class StarCatalogServiceTests: XCTestCase {

    private var service: StarCatalogService!

    override func setUp() async throws {
        try await super.setUp()
        guard let path = Bundle.main.path(forResource: "hipparcos_tycho2", ofType: "sqlite") else {
            XCTFail("Star catalog not found in test bundle")
            return
        }
        var config = Configuration()
        config.readonly = true
        let db = try DatabaseQueue(path: path, configuration: config)
        service = StarCatalogService(catalogDB: db)
    }

    func testStarsVisible_mag6p5_count() async throws {
        let stars = try await service.starsVisible(
            above: 6.5,
            centerRA: 180.0,
            centerDec: 30.0,
            fieldDegrees: 80.0
        )
        XCTAssertGreaterThanOrEqual(stars.count, 500)
        XCTAssertLessThanOrEqual(stars.count, 5000)
    }

    func testStarsVisible_mag4p0_fewer() async throws {
        let stars = try await service.starsVisible(
            above: 4.0,
            centerRA: 180.0,
            centerDec: 30.0,
            fieldDegrees: 80.0
        )
        XCTAssertLessThan(stars.count, 500)
    }

    func testStarsVisible_allBelowThreshold() async throws {
        let magnitude = 5.0
        let stars = try await service.starsVisible(
            above: magnitude,
            centerRA: 100.0,
            centerDec: 20.0,
            fieldDegrees: 80.0
        )
        for star in stars {
            XCTAssertLessThanOrEqual(
                star.vmag, magnitude,
                "Star \(star.id) has vmag \(star.vmag) > \(magnitude)"
            )
        }
    }

    func testStarsVisible_respectsLimit() async throws {
        let stars = try await service.starsVisible(
            above: 10.0,
            centerRA: 180.0,
            centerDec: 0.0,
            fieldDegrees: 80.0
        )
        XCTAssertLessThanOrEqual(stars.count, ComparisonConstants.maxStarSprites)
    }

    func testStarsVisible_raWraparound() async throws {
        // Center near RA 355 with 80° field → should include stars near RA 0-30
        let stars = try await service.starsVisible(
            above: 6.0,
            centerRA: 355.0,
            centerDec: 30.0,
            fieldDegrees: 80.0
        )
        // Should find some stars with RA < 30 (in the wrapped region)
        let wrappedStars = stars.filter { $0.ra < 30.0 }
        XCTAssertGreaterThan(wrappedStars.count, 0, "Expected stars in wrapped RA region near 0°")
    }

    func testStarsVisible_nearPole() async throws {
        // Near north pole — shouldn't crash
        let stars = try await service.starsVisible(
            above: 6.0,
            centerRA: 0.0,
            centerDec: 85.0,
            fieldDegrees: 80.0
        )
        XCTAssertGreaterThan(stars.count, 0)
    }

    func testStarsVisible_performance() async throws {
        // Verify query completes in under 50ms
        let start = CFAbsoluteTimeGetCurrent()
        _ = try await service.starsVisible(
            above: 6.5,
            centerRA: 180.0,
            centerDec: 30.0,
            fieldDegrees: 80.0
        )
        let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
        XCTAssertLessThan(elapsed, 50.0, "Query took \(elapsed)ms, expected < 50ms")
    }

    func testZenithRADec_knownValues() {
        // Zenith RA = LST, Dec = latitude
        let components = DateComponents(
            calendar: .init(identifier: .gregorian),
            timeZone: .init(identifier: "UTC"),
            year: 2024, month: 6, day: 21, hour: 0, minute: 0
        )
        let date = components.date!
        let zenith = StarCatalogService.zenithRADec(
            latitude: 37.77,
            longitude: -122.41,
            date: date
        )
        XCTAssertEqual(zenith.dec, 37.77, accuracy: 0.001)
        // RA should be LST, which is a valid angle
        XCTAssertGreaterThanOrEqual(zenith.ra, 0.0)
        XCTAssertLessThan(zenith.ra, 360.0)
    }
}
