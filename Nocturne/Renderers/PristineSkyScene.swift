import SpriteKit

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

    /// Render the Milky Way as a glowing band along the galactic equator.
    func addMilkyWay() {
        let fieldRadians = fieldDegrees * .pi / 180.0
        let pixelsPerRadian = min(size.width, size.height) / fieldRadians

        // Sample points along the galactic equator (b = 0)
        var points: [CGPoint] = []
        for i in 0..<36 {
            let galLon = Double(i) * 10.0
            let (ra, dec) = Astrometry.galacticToEquatorial(l: galLon, b: 0)
            guard let projected = Astrometry.gnomonicProject(
                starRA: ra, starDec: dec,
                centerRA: centerRA, centerDec: centerDec
            ) else { continue }

            let screenX = size.width / 2.0 + projected.x * pixelsPerRadian
            let screenY = size.height / 2.0 + projected.y * pixelsPerRadian

            // Only include points near the visible area (with generous margin)
            guard screenX > -size.width, screenX < size.width * 2,
                  screenY > -size.height, screenY < size.height * 2 else { continue }

            points.append(CGPoint(x: screenX, y: screenY))
        }

        guard points.count >= 2 else { return }

        // Sort points by x to get a smooth path
        points.sort { $0.x < $1.x }

        let path = CGMutablePath()
        path.move(to: points[0])
        for point in points.dropFirst() {
            path.addLine(to: point)
        }

        let band = SKShapeNode(path: path)
        band.name = "milkyWay"
        band.strokeColor = SKColor(
            white: 0.9,
            alpha: MilkyWayConstants.bandOpacity
        )
        band.lineWidth = MilkyWayConstants.bandWidthDegrees * pixelsPerRadian * .pi / 180.0
        band.lineCap = .round
        band.lineJoin = .round
        band.glowWidth = band.lineWidth * 0.4
        band.zPosition = -100 // behind stars
        addChild(band)
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
