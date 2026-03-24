import Foundation
import GRDB

struct Star: Identifiable, Sendable {
    let id: Int                     // Tycho-2 catalog number
    let ra: Double                  // Right ascension, degrees
    let dec: Double                 // Declination, degrees
    let vmag: Double                // Visual magnitude
    let colorIndex: Double?         // B-V color index for star color tinting
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
