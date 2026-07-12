import Foundation
import GRDB

struct Star: Identifiable, Sendable {
    let id: Int                     // Gaia DR3 source identifier
    let ra: Double                  // Right ascension, degrees
    let dec: Double                 // Declination, degrees
    let vmag: Double                // Gaia G-band mean magnitude
    let colorIndex: Double?         // Gaia BP-RP color for star tinting
}

// MARK: - GRDB FetchableRecord (read-only)

extension Star: FetchableRecord {
    init(row: Row) throws {
        id = row["id"]
        ra = row["ra"]
        dec = row["dec"]
        vmag = row["vmag"]
        colorIndex = row["bv"]
    }
}
