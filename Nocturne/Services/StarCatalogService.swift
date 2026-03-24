import Foundation
import GRDB
import os

/// Queries the bundled Hipparcos/Tycho-2 star catalog for visible stars
/// within a given field of view.
actor StarCatalogService {

    private let catalogDB: DatabaseQueue
    private let logger = Logger(subsystem: "com.nocturne.app", category: "StarCatalogService")

    init() throws {
        guard let db = try DatabaseManager.openStarCatalog() else {
            throw StarCatalogError.catalogNotFound
        }
        self.catalogDB = db
    }

    /// For testing with an explicit database.
    init(catalogDB: DatabaseQueue) {
        self.catalogDB = catalogDB
    }

    /// Query stars visible within a field of view.
    ///
    /// - Parameters:
    ///   - magnitude: Maximum visual magnitude to include
    ///   - centerRA: Right ascension of field center (0–360°)
    ///   - centerDec: Declination of field center (−90 to +90°)
    ///   - fieldDegrees: Diagonal field of view in degrees
    /// - Returns: Up to `ComparisonConstants.maxStarSprites` stars, brightest first
    func starsVisible(
        above magnitude: Double,
        centerRA: Double,
        centerDec: Double,
        fieldDegrees: Double
    ) throws -> [Star] {
        let halfField = fieldDegrees / 2.0
        let decMin = max(-90.0, centerDec - halfField)
        let decMax = min(90.0, centerDec + halfField)

        // RA correction for declination (RA degrees shrink near poles)
        let cosDec = cos(centerDec * .pi / 180.0)
        let raHalfSpan = cosDec > 0.01 ? halfField / cosDec : 180.0
        let raMin = centerRA - raHalfSpan
        let raMax = centerRA + raHalfSpan

        let limit = ComparisonConstants.maxStarSprites

        return try catalogDB.read { db in
            let needsWraparound = raMin < 0 || raMax > 360

            if needsWraparound {
                let wrappedMin = fmod(fmod(raMin, 360.0) + 360.0, 360.0)
                let wrappedMax = fmod(raMax, 360.0)
                return try Star.fetchAll(db, sql: """
                    SELECT id, ra, dec, vmag, bv FROM stars
                    WHERE vmag <= ?
                      AND dec BETWEEN ? AND ?
                      AND (ra >= ? OR ra <= ?)
                    ORDER BY vmag ASC
                    LIMIT ?
                    """,
                    arguments: [magnitude, decMin, decMax, wrappedMin, wrappedMax, limit]
                )
            } else {
                return try Star.fetchAll(db, sql: """
                    SELECT id, ra, dec, vmag, bv FROM stars
                    WHERE vmag <= ?
                      AND dec BETWEEN ? AND ?
                      AND ra BETWEEN ? AND ?
                    ORDER BY vmag ASC
                    LIMIT ?
                    """,
                    arguments: [magnitude, decMin, decMax, raMin, raMax, limit]
                )
            }
        }
    }

    /// Compute the RA/Dec of zenith for an observer at a given location and time.
    /// By definition: zenith RA = Local Sidereal Time, zenith Dec = observer latitude.
    nonisolated static func zenithRADec(
        latitude: Double,
        longitude: Double,
        date: Date
    ) -> (ra: Double, dec: Double) {
        let lst = Astrometry.localSiderealTime(longitude: longitude, date: date)
        return (ra: lst, dec: latitude)
    }
}

enum StarCatalogError: Error, Sendable {
    case catalogNotFound
}
