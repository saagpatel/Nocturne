import SpriteKit
import os

/// Loads measurement data, queries the star catalog, and assembles
/// both SpriteKit scenes for the comparison view.
@Observable
@MainActor
final class ComparisonViewModel {

    private(set) var userScene: UserSkyScene?
    private(set) var pristineScene: PristineSkyScene?
    private(set) var isLoading = true
    private(set) var error: String?

    let measurement: MeasurementRecord

    private let logger = Logger(subsystem: "com.nocturnn.app", category: "ComparisonViewModel")

    // MARK: - Computed Stats

    var skyBrightness: Double { measurement.skyBrightness }
    var bortleClass: Int { measurement.bortleClass }

    var limitingMagnitude: Double {
        UserSkyScene.limitingMagnitude(for: measurement.skyBrightness)
    }

    // Stored so SwiftUI observes them; SpriteKit renders later, in didMove(to:),
    // and its own counter is not observable.
    private(set) var userStarCount = 0
    private(set) var pristineStarCount = 0

    init(measurement: MeasurementRecord) {
        self.measurement = measurement
    }

    // MARK: - Scene Loading

    /// Load stars from the catalog and build both scenes.
    func loadScenes(sceneSize: CGSize) async {
        isLoading = true
        error = nil

        do {
            let catalogService = try StarCatalogService()

            // Compute zenith RA/Dec at measurement location and time
            let zenith = StarCatalogService.zenithRADec(
                latitude: measurement.latitude,
                longitude: measurement.longitude,
                date: measurement.measuredAt
            )

            // Query all stars visible at pristine limiting magnitude (superset)
            let pristineLimitingMag = UserSkyScene.limitingMagnitude(
                for: SkyBrightnessConstants.pristineMagArcsec2
            )

            let stars = try await catalogService.starsVisible(
                above: pristineLimitingMag,
                centerRA: zenith.ra,
                centerDec: zenith.dec,
                fieldDegrees: ComparisonConstants.fieldOfViewDegrees
            )

            logger.info(
                "Loaded \(stars.count) stars for comparison (zenith RA=\(zenith.ra), Dec=\(zenith.dec))"
            )

            // Build user sky scene
            userScene = UserSkyScene(
                size: sceneSize,
                stars: stars,
                centerRA: zenith.ra,
                centerDec: zenith.dec,
                skyBrightness: measurement.skyBrightness
            )

            // Build pristine sky scene (same stars, higher limiting magnitude)
            pristineScene = PristineSkyScene(
                size: sceneSize,
                stars: stars,
                centerRA: zenith.ra,
                centerDec: zenith.dec
            )

            userStarCount = userScene?.projectedStars().count ?? 0
            pristineStarCount = pristineScene?.projectedStars().count ?? 0

            isLoading = false
        } catch {
            logger.error("Failed to load comparison scenes: \(error.localizedDescription)")
            self.error = "Unable to load star catalog."
            isLoading = false
        }
    }
}
