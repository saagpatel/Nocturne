import Foundation
import os

enum CalibrationService {

    private static let logger = Logger(
        subsystem: "com.nocturne.app",
        category: "CalibrationService"
    )

    /// Load the calibration table from the app bundle.
    static func loadTable() -> CalibrationTable? {
        guard let url = Bundle.main.url(
            forResource: CalibrationConstants.calibrationFileName,
            withExtension: "json"
        ) else {
            logger.error("calibration_table.json not found in bundle")
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(CalibrationTable.self, from: data)
        } catch {
            logger.error("Failed to decode calibration table: \(error.localizedDescription)")
            return nil
        }
    }

    /// Look up calibration coefficients for a specific device model.
    static func coefficients(
        for model: String,
        in table: CalibrationTable
    ) -> CalibrationCoefficients? {
        table.coefficients.first { $0.iphoneModel == model }
    }

    /// Convenience: load table from bundle and look up by model.
    static func coefficients(for model: String) -> CalibrationCoefficients? {
        guard let table = loadTable() else { return nil }
        return coefficients(for: model, in: table)
    }
}
