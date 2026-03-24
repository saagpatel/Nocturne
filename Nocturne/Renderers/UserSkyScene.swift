import SpriteKit

/// Renders stars visible at the user's measured sky brightness.
/// Filters the star list to only those brighter than the computed limiting magnitude.
final class UserSkyScene: SkyScene {

    let skyBrightness: Double

    /// Computed limiting magnitude from sky brightness.
    /// Corrected formula: `limitingMag = 0.5 * skyBrightness - 4.5`
    /// Matches: 18.0 → 4.5, 20.0 → 5.5, 22.0 → 6.5
    var limitingMagnitude: Double {
        Self.limitingMagnitude(for: skyBrightness)
    }

    init(
        size: CGSize,
        stars: [Star],
        centerRA: Double,
        centerDec: Double,
        fieldDegrees: Double = ComparisonConstants.fieldOfViewDegrees,
        skyBrightness: Double
    ) {
        self.skyBrightness = skyBrightness
        super.init(
            size: size,
            stars: stars,
            centerRA: centerRA,
            centerDec: centerDec,
            fieldDegrees: fieldDegrees
        )
    }

    /// Compute limiting magnitude for a given sky brightness.
    static func limitingMagnitude(for skyBrightness: Double) -> Double {
        ComparisonConstants.limitingMagScale * skyBrightness
            - ComparisonConstants.limitingMagOffset
    }

    override func filteredStars() -> [Star] {
        let limit = limitingMagnitude
        return stars.filter { $0.vmag <= limit }
    }
}
