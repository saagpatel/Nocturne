import Foundation

// MARK: - Camera

enum CameraError: Error, Sendable {
    case permissionDenied
    case permissionRestricted
    case deviceNotAvailable
    case captureFailure(underlying: String)
    case sessionNotRunning
    case unsupportedPixelFormat
}

// MARK: - Location

enum LocationError: Error, Sendable {
    case permissionDenied
    case permissionRestricted
    case timeout
    case locationUnavailable
}

// MARK: - Weather

enum WeatherError: Error, Sendable {
    case networkFailure(underlying: String)
    case invalidResponse
    case noDataForCurrentHour
}

// MARK: - Validation

enum ValidationFailure: Sendable {
    case notDarkEnough(solarAltitude: Double)
    case deviceTilt(degrees: Double)
    case lightSourceInFrame(hotPixelFraction: Double)
}

enum ValidationResult: Sendable {
    case valid(ValidationReport)
    case rejected(ValidationFailure)
}

struct ValidationReport: Sendable {
    let solarAltitudeDeg: Double
    let deviceTiltDeg: Double
    let hotPixelFraction: Double
    let cloudCoverPct: Int?
    let isCloudy: Bool
}

// MARK: - Measurement Pipeline

enum MeasurementError: Error, Sendable {
    case camera(CameraError)
    case location(LocationError)
    case validation(ValidationFailure)
    case databaseFailure(underlying: String)
}
