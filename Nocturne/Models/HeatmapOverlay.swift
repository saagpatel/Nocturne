import MapKit

/// An MKOverlay representing a single heatmap tile cell.
/// Each tile covers a `gridSizeDegrees × gridSizeDegrees` cell on the map.
final class HeatmapOverlay: NSObject, MKOverlay {
    let tile: HeatmapTile
    let gridSizeDegrees: Double
    let coordinate: CLLocationCoordinate2D
    let boundingMapRect: MKMapRect

    init(tile: HeatmapTile, gridSizeDegrees: Double = MapConstants.tileGridSizeDegrees) {
        self.tile = tile
        self.gridSizeDegrees = gridSizeDegrees
        self.coordinate = CLLocationCoordinate2D(
            latitude: tile.cellLat,
            longitude: tile.cellLon
        )

        // Build bounding rect from tile cell corners
        let half = gridSizeDegrees / 2.0
        let sw = MKMapPoint(CLLocationCoordinate2D(
            latitude: tile.cellLat - half,
            longitude: tile.cellLon - half
        ))
        let ne = MKMapPoint(CLLocationCoordinate2D(
            latitude: tile.cellLat + half,
            longitude: tile.cellLon + half
        ))
        self.boundingMapRect = MKMapRect(
            x: min(sw.x, ne.x),
            y: min(sw.y, ne.y),
            width: abs(ne.x - sw.x),
            height: abs(ne.y - sw.y)
        )

        super.init()
    }
}
