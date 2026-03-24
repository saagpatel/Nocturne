import Foundation

struct CalibrationCoefficients: Codable, Sendable {
    let iphoneModel: String         // Machine identifier, e.g. "iPhone15,2"
    let friendlyName: String        // e.g. "iPhone 15 Pro"
    let a: Double                   // y = a * log10(x) + b + c * temp_c
    let b: Double
    let c: Double                   // Temperature coefficient
    let version: String             // calibration_table.json version
}

struct CalibrationTable: Codable, Sendable {
    let version: String
    let coefficients: [CalibrationCoefficients]
}
