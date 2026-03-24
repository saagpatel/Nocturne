import Foundation

// MARK: - Sky Brightness

enum SkyBrightnessConstants {
    static let targetISO: Float = 1600
    static let targetExposure: Double = 4.0           // seconds
    static let pristineMagArcsec2: Double = 22.0      // Bortle Class 1
    static let urbanMinMagArcsec2: Double = 16.0      // Bortle Class 9
    static let nakedEyeLimitingMagOffset: Double = -5.0  // NELM ≈ SQM - 5 (approx)

    /// Bortle class thresholds (mag/arcsec²), ordered by descending minMag.
    /// First match where skyBrightness >= minMag determines the Bortle class.
    static let bortleThresholds: [(bortleClass: Int, minMag: Double)] = [
        (1, 21.75), (2, 21.5), (3, 21.25), (4, 20.5),
        (5, 19.5),  (6, 18.5), (7, 17.5),  (8, 16.5), (9, 0.0)
    ]
}

// MARK: - Database

enum DatabaseConstants {
    static let localDatabaseName = "nocturne_local.sqlite"
    static let starCatalogName = "hipparcos_tycho2"
}

// MARK: - Calibration

enum CalibrationConstants {
    static let calibrationFileName = "calibration_table"
    static let currentVersion = "1.0"
}

// MARK: - Upload

enum UploadConstants {
    static let maxRetryAttempts = 3
    static let batchSize = 10
}

// MARK: - Map

enum MapConstants {
    static let tileCacheDurationSeconds: Double = 300.0
    static let mapDebounceMilliseconds: Int = 500
    static let tileGridSizeDegrees: Double = 0.1
    static let defaultRegionSpanDegrees: Double = 5.0

    // Sky brightness color thresholds (mag/arcsec²)
    static let pristineThreshold: Double = 21.0   // > 21 → deep blue
    static let ruralThreshold: Double = 19.0       // 19–21 → green
    static let suburbanThreshold: Double = 17.0    // 17–19 → orange/yellow
    // < 17 → deep red (urban/city)
}

// MARK: - Validation

enum ValidationConstants {
    static let maxSolarAltitudeDeg: Double = -6.0    // civil twilight
    static let maxTiltFromZenithDeg: Double = 20.0
    static let maxHotPixelFraction: Double = 0.01    // 1%
    static let cloudyCoverThreshold: Int = 50        // percent
}

// MARK: - Location

enum LocationConstants {
    static let locationTimeoutSeconds: Double = 10.0
    static let minimumAccuracyMeters: Double = 100.0
}

// MARK: - Weather

enum WeatherConstants {
    static let openMeteoBaseURL = "https://api.open-meteo.com/v1/forecast"
    static let requestTimeoutSeconds: Double = 10.0
}

// MARK: - Pixel Processing

enum PixelConstants {
    static let centerCropSize: Int = 240
    static let gammaExponent: Double = 2.2
    static let referenceLuminance: Double = 80.0  // cd/m² at pixel value 1.0
}

// MARK: - Rec.709 Luma

enum LumaCoefficients {
    static let red: Double = 0.2126
    static let green: Double = 0.7152
    static let blue: Double = 0.0722
}

// MARK: - Comparison View

enum ComparisonConstants {
    static let fieldOfViewDegrees: Double = 80.0
    static let maxStarSprites: Int = 5_000
    static let limitingMagOffset: Double = 4.5
    static let limitingMagScale: Double = 0.5
    // limitingMag = limitingMagScale * skyBrightness - limitingMagOffset
}

// MARK: - Star Rendering

enum StarRenderConstants {
    static let brightDiameter: CGFloat = 12.0
    static let mediumDiameter: CGFloat = 6.0
    static let faintDiameter: CGFloat = 3.0
    static let brightMagThreshold: Double = 2.0
    static let mediumMagThreshold: Double = 4.5
    static let minStarOpacity: CGFloat = 0.3
}

// MARK: - Milky Way

enum MilkyWayConstants {
    static let galacticCenterRA: Double = 266.405
    static let galacticCenterDec: Double = -28.936
    static let galacticInclination: Double = 62.87
    static let bandWidthDegrees: Double = 20.0
    static let bandOpacity: CGFloat = 0.15
}

// MARK: - Deep Sky Objects

enum DeepSkyConstants {
    static let andromedaRA: Double = 10.6847
    static let andromedaDec: Double = 41.2687
    static let andromedaGlowRadius: CGFloat = 24.0
    static let andromedaGlowOpacity: CGFloat = 0.25
}
