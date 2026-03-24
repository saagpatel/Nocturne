import Foundation

struct HeatmapTile: Codable, Sendable {
    let cellLat: Double
    let cellLon: Double
    let avgBrightness: Double       // mag/arcsec²
    let measurementCount: Int
    let avgBortle: Int
}
