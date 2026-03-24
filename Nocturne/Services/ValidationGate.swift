import CoreLocation
import Foundation

/// Input context for measurement validation, gathered by the caller before validation.
struct ValidationContext: Sendable {
    let location: CLLocation
    let date: Date
    let gravityX: Double
    let gravityY: Double
    let gravityZ: Double
    let hotPixelFraction: Double
    let cloudCoverPct: Int?
}

/// 4-gate validation pipeline for sky brightness measurements.
/// Gates run in order (cheapest first): solar → tilt → hot-pixel → weather (tag only).
struct ValidationGate: Sendable {

    /// Validate a measurement context against all 4 gates.
    /// Returns `.rejected` on the first failing gate (fail-fast).
    /// Weather (gate 4) tags but never rejects.
    func validate(context: ValidationContext) -> ValidationResult {
        let latitude = context.location.coordinate.latitude
        let longitude = context.location.coordinate.longitude

        // Gate 1: Solar altitude — must be below civil twilight
        let solarAlt = Self.solarAltitude(
            latitude: latitude,
            longitude: longitude,
            date: context.date
        )
        guard solarAlt < ValidationConstants.maxSolarAltitudeDeg else {
            return .rejected(.notDarkEnough(solarAltitude: solarAlt))
        }

        // Gate 2: Device tilt — must be within threshold of zenith
        let tilt = Self.tiltFromZenith(
            gravityX: context.gravityX,
            gravityY: context.gravityY,
            gravityZ: context.gravityZ
        )
        guard tilt < ValidationConstants.maxTiltFromZenithDeg else {
            return .rejected(.deviceTilt(degrees: tilt))
        }

        // Gate 3: Hot pixels — reject if too many saturated pixels
        guard context.hotPixelFraction < ValidationConstants.maxHotPixelFraction else {
            return .rejected(.lightSourceInFrame(hotPixelFraction: context.hotPixelFraction))
        }

        // Gate 4: Cloud cover — tag but never reject
        let isCloudy: Bool
        if let pct = context.cloudCoverPct {
            isCloudy = pct > ValidationConstants.cloudyCoverThreshold
        } else {
            isCloudy = false
        }

        let report = ValidationReport(
            solarAltitudeDeg: solarAlt,
            deviceTiltDeg: tilt,
            hotPixelFraction: context.hotPixelFraction,
            cloudCoverPct: context.cloudCoverPct,
            isCloudy: isCloudy
        )
        return .valid(report)
    }

    // MARK: - Solar Altitude (Jean Meeus simplified)

    /// Compute solar altitude in degrees for a given location and time.
    /// Negative values = below horizon. Uses simplified Jean Meeus formula.
    /// Accuracy: ±0.5° — sufficient for the -6° civil twilight threshold.
    static func solarAltitude(
        latitude: Double,
        longitude: Double,
        date: Date
    ) -> Double {
        let jd = Astrometry.julianDate(from: date)
        let t = (jd - 2_451_545.0) / 36_525.0

        // Solar position (Jean Meeus simplified)
        let l0 = fmod(280.46646 + 36_000.76983 * t, 360.0)
        let m = fmod(357.52911 + 35_999.05029 * t, 360.0)
        let mRad = m * .pi / 180.0

        let c = (1.9146 - 0.004817 * t) * sin(mRad)
            + 0.019993 * sin(2 * mRad)
            + 0.000290 * sin(3 * mRad)

        let theta = l0 + c
        let thetaRad = theta * .pi / 180.0

        let epsilon = 23.439291 - 0.0130042 * t
        let epsilonRad = epsilon * .pi / 180.0

        let sinDec = sin(epsilonRad) * sin(thetaRad)
        let solarDec = asin(sinDec) * 180.0 / .pi

        let solarRA = atan2(
            cos(epsilonRad) * sin(thetaRad),
            cos(thetaRad)
        ) * 180.0 / .pi

        let (altitude, _) = Astrometry.equatorialToHorizontal(
            ra: solarRA, dec: solarDec,
            latitude: latitude, longitude: longitude, date: date
        )
        return altitude
    }

    // MARK: - Device Tilt

    /// Compute angle from zenith (straight up) in degrees from gravity vector.
    /// gravity = (0, 0, -1) when phone is face-up and level → returns 0°.
    /// gravity = (0, -1, 0) when phone is upright (portrait) → returns 90°.
    static func tiltFromZenith(
        gravityX: Double,
        gravityY: Double,
        gravityZ: Double
    ) -> Double {
        let magnitude = sqrt(gravityX * gravityX + gravityY * gravityY + gravityZ * gravityZ)
        guard magnitude > 0.001 else { return 90.0 }
        let cosAngle = -gravityZ / magnitude
        let clampedCos = max(-1.0, min(1.0, cosAngle))
        return acos(clampedCos) * 180.0 / .pi
    }
}
