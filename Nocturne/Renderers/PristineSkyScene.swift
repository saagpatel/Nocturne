import SpriteKit
import UIKit

/// Renders a pristine Bortle Class 1 sky (22.0 mag/arcsec²).
/// Includes Milky Way band and Andromeda galaxy (M31).
final class PristineSkyScene: SkyScene {

    private let pristineLimitingMag: Double

    override init(
        size: CGSize,
        stars: [Star],
        centerRA: Double,
        centerDec: Double,
        fieldDegrees: Double = ComparisonConstants.fieldOfViewDegrees
    ) {
        self.pristineLimitingMag = UserSkyScene.limitingMagnitude(
            for: SkyBrightnessConstants.pristineMagArcsec2
        )
        super.init(
            size: size,
            stars: stars,
            centerRA: centerRA,
            centerDec: centerDec,
            fieldDegrees: fieldDegrees
        )
    }

    override func filteredStars() -> [Star] {
        stars.filter { $0.vmag <= pristineLimitingMag }
    }

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        addMilkyWay()
        addAndromeda()
    }

    // MARK: - Milky Way

    /// Render the Milky Way as a soft band along the galactic equator.
    ///
    /// A gnomonic projection maps the galactic equator (a great circle) to a straight
    /// line, so the band is a gradient across that line. It fades out at the edge of
    /// the catalog field, so it never extends past the stars it sits behind. Drawn as
    /// one prerendered sprite: a stroked `SKShapeNode` this wide breaks up into grey
    /// slivers.
    func addMilkyWay() {
        let fieldRadians = fieldDegrees * .pi / 180.0
        let pixelsPerRadian = min(size.width, size.height) / fieldRadians
        let center = CGPoint(x: size.width / 2.0, y: size.height / 2.0)

        var points: [CGPoint] = []
        for i in 0..<360 {
            let (ra, dec) = Astrometry.galacticToEquatorial(l: Double(i), b: 0)
            guard let projected = Astrometry.gnomonicProject(
                starRA: ra, starDec: dec,
                centerRA: centerRA, centerDec: centerDec
            ) else { continue }
            points.append(CGPoint(
                x: center.x + projected.x * pixelsPerRadian,
                y: center.y + projected.y * pixelsPerRadian
            ))
        }
        guard let first = points.first,
              let far = points.max(by: { first.distance(to: $0) < first.distance(to: $1) }),
              first.distance(to: far) > 1 else { return }

        // Field edge: the catalog query covers half the field in every direction.
        let fieldRadius = tan(fieldRadians / 2.0) * pixelsPerRadian
        let angle = atan2(far.y - first.y, far.x - first.x)
        let direction = CGPoint(x: cos(angle), y: sin(angle))
        // Point on the band's center line nearest the scene center.
        let along = (center.x - first.x) * direction.x + (center.y - first.y) * direction.y
        let lineCenter = CGPoint(x: first.x + direction.x * along, y: first.y + direction.y * along)
        guard center.distance(to: lineCenter) < fieldRadius else { return }

        let halfWidth = MilkyWayConstants.bandWidthDegrees * .pi / 180.0 * pixelsPerRadian
        let image = UIGraphicsImageRenderer(size: size).image { ctx in
            let cg = ctx.cgContext
            // UIKit draws top-down; SpriteKit's y axis points up.
            cg.translateBy(x: 0, y: size.height)
            cg.scaleBy(x: 1, y: -1)

            let peak = UIColor(white: 0.9, alpha: MilkyWayConstants.bandOpacity).cgColor
            let clear = UIColor(white: 0.9, alpha: 0).cgColor
            guard let band = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [clear, peak, clear] as CFArray,
                locations: [0, 0.5, 1]
            ), let fade = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [UIColor.white.cgColor, UIColor.white.cgColor,
                         UIColor.white.withAlphaComponent(0).cgColor] as CFArray,
                locations: [0, 0.75, 1]
            ) else { return }

            let normal = CGPoint(x: -direction.y, y: direction.x)
            cg.drawLinearGradient(
                band,
                start: CGPoint(x: lineCenter.x - normal.x * halfWidth,
                               y: lineCenter.y - normal.y * halfWidth),
                end: CGPoint(x: lineCenter.x + normal.x * halfWidth,
                             y: lineCenter.y + normal.y * halfWidth),
                options: []
            )
            cg.setBlendMode(.destinationIn)
            cg.drawRadialGradient(
                fade,
                startCenter: center, startRadius: 0,
                endCenter: center, endRadius: fieldRadius,
                // Past the end radius the clear stop must still be drawn, or
                // destinationIn leaves the band outside the field untouched.
                options: .drawsAfterEndLocation
            )
        }

        let sprite = SKSpriteNode(texture: SKTexture(image: image), size: size)
        sprite.name = "milkyWay"
        sprite.position = center
        sprite.zPosition = -100 // behind stars
        addChild(sprite)
    }

    // MARK: - Andromeda (M31)

    /// Render Andromeda galaxy as a soft glowing ellipse.
    func addAndromeda() {
        guard let projected = Astrometry.gnomonicProject(
            starRA: DeepSkyConstants.andromedaRA,
            starDec: DeepSkyConstants.andromedaDec,
            centerRA: centerRA,
            centerDec: centerDec
        ) else { return }

        let fieldRadians = fieldDegrees * .pi / 180.0
        let pixelsPerRadian = min(size.width, size.height) / fieldRadians

        let screenX = size.width / 2.0 + projected.x * pixelsPerRadian
        let screenY = size.height / 2.0 + projected.y * pixelsPerRadian

        let glow = SKShapeNode(ellipseOf: CGSize(
            width: DeepSkyConstants.andromedaGlowRadius * 2,
            height: DeepSkyConstants.andromedaGlowRadius
        ))
        glow.name = "andromeda"
        glow.position = CGPoint(x: screenX, y: screenY)
        glow.fillColor = SKColor(
            white: 0.8,
            alpha: DeepSkyConstants.andromedaGlowOpacity
        )
        glow.strokeColor = .clear
        glow.glowWidth = 8
        glow.zRotation = 0.6 // ~35° position angle
        glow.zPosition = -50 // behind stars, in front of Milky Way
        addChild(glow)
    }
}

private extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        hypot(other.x - x, other.y - y)
    }
}
