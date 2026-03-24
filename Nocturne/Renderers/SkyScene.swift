import SpriteKit
import UIKit

/// Base SKScene for rendering a star field using gnomonic projection.
/// Subclasses (UserSkyScene, PristineSkyScene) control which stars are rendered.
class SkyScene: SKScene {

    var stars: [Star]
    var centerRA: Double
    var centerDec: Double
    var fieldDegrees: Double
    private(set) var renderedStarCount: Int = 0

    private var brightTexture: SKTexture?
    private var mediumTexture: SKTexture?
    private var faintTexture: SKTexture?

    init(
        size: CGSize,
        stars: [Star],
        centerRA: Double,
        centerDec: Double,
        fieldDegrees: Double = ComparisonConstants.fieldOfViewDegrees
    ) {
        self.stars = stars
        self.centerRA = centerRA
        self.centerDec = centerDec
        self.fieldDegrees = fieldDegrees
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = .black
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        generateStarTextures()
        renderStars()
    }

    // MARK: - Texture Generation

    /// Generate three procedural radial gradient textures for star rendering.
    func generateStarTextures() {
        brightTexture = makeStarTexture(diameter: StarRenderConstants.brightDiameter)
        mediumTexture = makeStarTexture(diameter: StarRenderConstants.mediumDiameter)
        faintTexture = makeStarTexture(diameter: StarRenderConstants.faintDiameter)
    }

    private func makeStarTexture(diameter: CGFloat) -> SKTexture {
        let renderSize = CGSize(width: diameter, height: diameter)
        let renderer = UIGraphicsImageRenderer(size: renderSize)
        let image = renderer.image { ctx in
            let center = CGPoint(x: diameter / 2, y: diameter / 2)
            let colors = [
                UIColor.white.cgColor,
                UIColor.white.withAlphaComponent(0).cgColor,
            ]
            guard let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors as CFArray,
                locations: [0, 1]
            ) else { return }
            ctx.cgContext.drawRadialGradient(
                gradient,
                startCenter: center, startRadius: 0,
                endCenter: center, endRadius: diameter / 2,
                options: .drawsAfterEndLocation
            )
        }
        return SKTexture(image: image)
    }

    // MARK: - Star Rendering

    /// Project and render all stars onto the scene. Override in subclasses to filter.
    func renderStars() {
        removeAllChildren()
        renderedStarCount = 0

        let starsToRender = filteredStars()
        let fieldRadians = fieldDegrees * .pi / 180.0
        let pixelsPerRadian = min(size.width, size.height) / fieldRadians

        for star in starsToRender {
            guard let projected = Astrometry.gnomonicProject(
                starRA: star.ra,
                starDec: star.dec,
                centerRA: centerRA,
                centerDec: centerDec
            ) else { continue }

            let screenX = size.width / 2.0 + projected.x * pixelsPerRadian
            let screenY = size.height / 2.0 + projected.y * pixelsPerRadian

            // Skip if off-screen with margin
            guard screenX > -20, screenX < size.width + 20,
                  screenY > -20, screenY < size.height + 20 else { continue }

            let texture = textureForMagnitude(star.vmag)
            let sprite = SKSpriteNode(texture: texture)
            sprite.position = CGPoint(x: screenX, y: screenY)
            sprite.alpha = opacityForMagnitude(star.vmag)
            sprite.color = colorForBV(star.colorIndex)
            sprite.colorBlendFactor = star.colorIndex != nil ? 1.0 : 0
            sprite.zPosition = CGFloat(-star.vmag) // bright stars in front
            addChild(sprite)
            renderedStarCount += 1
        }
    }

    /// Override in subclasses to filter stars by limiting magnitude.
    func filteredStars() -> [Star] {
        stars
    }

    // MARK: - Star Properties

    private func textureForMagnitude(_ vmag: Double) -> SKTexture {
        if vmag <= StarRenderConstants.brightMagThreshold {
            return brightTexture ?? SKTexture()
        } else if vmag <= StarRenderConstants.mediumMagThreshold {
            return mediumTexture ?? SKTexture()
        } else {
            return faintTexture ?? SKTexture()
        }
    }

    private func opacityForMagnitude(_ vmag: Double) -> CGFloat {
        let maxMag = 6.5
        let t = max(0, min(1, vmag / maxMag))
        return 1.0 - t * (1.0 - StarRenderConstants.minStarOpacity)
    }

    func colorForBV(_ bv: Double?) -> SKColor {
        guard let bv else { return .white }
        switch bv {
        case ..<0.0:
            return SKColor(red: 0.7, green: 0.8, blue: 1.0, alpha: 1.0)
        case 0.0..<0.5:
            return .white
        case 0.5..<1.0:
            return SKColor(red: 1.0, green: 0.95, blue: 0.7, alpha: 1.0)
        case 1.0..<1.5:
            return SKColor(red: 1.0, green: 0.8, blue: 0.5, alpha: 1.0)
        default:
            return SKColor(red: 1.0, green: 0.6, blue: 0.4, alpha: 1.0)
        }
    }
}
