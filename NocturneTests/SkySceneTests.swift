import XCTest
@testable import Nocturne

final class SkySceneTests: XCTestCase {

    // MARK: - Limiting Magnitude Formula

    func testLimitingMag_urban() {
        // skyBrightness 18.0 → limiting mag 4.5
        let result = UserSkyScene.limitingMagnitude(for: 18.0)
        XCTAssertEqual(result, 4.5, accuracy: 0.01)
    }

    func testLimitingMag_pristine() {
        // skyBrightness 22.0 → limiting mag 6.5
        let result = UserSkyScene.limitingMagnitude(for: 22.0)
        XCTAssertEqual(result, 6.5, accuracy: 0.01)
    }

    func testLimitingMag_suburban() {
        // skyBrightness 20.0 → limiting mag 5.5
        let result = UserSkyScene.limitingMagnitude(for: 20.0)
        XCTAssertEqual(result, 5.5, accuracy: 0.01)
    }

    // MARK: - Scene Star Counts (structural)

    func testPristineScene_moreStarsThanUser() {
        // Given the same stars, pristine (mag 6.5 limit) should show more than
        // a user scene at brightness 19.0 (mag 5.0 limit)
        let stars = makeSampleStars()

        let userScene = UserSkyScene(
            size: CGSize(width: 300, height: 500),
            stars: stars,
            centerRA: 180.0,
            centerDec: 30.0,
            skyBrightness: 19.0
        )
        let pristineScene = PristineSkyScene(
            size: CGSize(width: 300, height: 500),
            stars: stars,
            centerRA: 180.0,
            centerDec: 30.0
        )

        let userFiltered = userScene.filteredStars()
        let pristineFiltered = pristineScene.filteredStars()

        XCTAssertGreaterThan(
            pristineFiltered.count,
            userFiltered.count,
            "Pristine should show more stars than user at brightness 19.0"
        )
    }

    // MARK: - Helpers

    private func makeSampleStars() -> [Star] {
        // Create a range of stars with different magnitudes
        (0..<100).map { i in
            Star(
                id: i,
                ra: 180.0 + Double(i % 10) * 2.0,  // clustered near center
                dec: 30.0 + Double(i / 10) * 2.0,
                vmag: Double(i) / 15.0 + 1.0,       // range 1.0 to ~7.7
                colorIndex: 0.5
            )
        }
    }
}
