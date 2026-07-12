import GRDB

enum Migration002_ResetProvisionalCalibration {
    static func migrate(_ db: Database) throws {
        // Earlier builds labeled provisional device profiles as calibrated.
        // Preserve readings while correcting that unsupported claim.
        try db.execute(sql: "UPDATE measurements SET is_calibrated = 0")
    }
}
