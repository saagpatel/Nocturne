import MapKit
import UIKit

/// Renders a single `HeatmapOverlay` tile as a filled circle colored by sky brightness.
///
/// Color mapping (mag/arcsec²):
///   > 21.0  → deep blue  (pristine dark sky)
///   19–21   → green      (rural sky)
///   17–19   → orange     (suburban sky)
///   < 17    → deep red   (urban/city sky)
///
/// Opacity scales with measurement count, clamped to [~0.37, 0.85].
final class HeatmapOverlayRenderer: MKOverlayRenderer {

    override func draw(
        _ mapRect: MKMapRect,
        zoomScale: MKZoomScale,
        in context: CGContext
    ) {
        guard let overlay = overlay as? HeatmapOverlay else { return }
        let tile = overlay.tile

        let color = Self.color(for: tile.avgBrightness)
        let opacity = min(0.3 + Double(tile.measurementCount) * 0.07, 0.85)

        context.setFillColor(color.withAlphaComponent(opacity).cgColor)
        context.setBlendMode(.normal)

        // Convert the overlay's bounding MKMapRect to CoreGraphics drawing coordinates.
        let drawRect = rect(for: overlay.boundingMapRect)
        let radius = min(drawRect.width, drawRect.height) / 2.0
        let center = CGPoint(x: drawRect.midX, y: drawRect.midY)

        context.addArc(
            center: center,
            radius: radius,
            startAngle: 0,
            endAngle: .pi * 2,
            clockwise: true
        )
        context.fillPath()
    }

    // MARK: - Color mapping

    private static func color(for brightness: Double) -> UIColor {
        if brightness > MapConstants.pristineThreshold {
            // > 21.0 mag/arcsec² → pristine dark sky → deep blue
            return UIColor(red: 0.1, green: 0.3, blue: 0.9, alpha: 1)
        } else if brightness > MapConstants.ruralThreshold {
            // 19–21 → rural sky → green
            return UIColor(red: 0.2, green: 0.8, blue: 0.3, alpha: 1)
        } else if brightness > MapConstants.suburbanThreshold {
            // 17–19 → suburban sky → orange/yellow
            return UIColor(red: 1.0, green: 0.7, blue: 0.1, alpha: 1)
        } else {
            // < 17 → urban/city sky → deep red
            return UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1)
        }
    }
}
