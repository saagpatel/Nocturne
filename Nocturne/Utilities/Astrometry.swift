import Foundation

/// Shared astrometry calculations for coordinate transforms.
/// All angles are in degrees unless otherwise noted.
enum Astrometry {

    // MARK: - Time

    /// Julian Date from a UTC Date.
    static func julianDate(from date: Date) -> Double {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )

        guard let year = components.year,
              let month = components.month,
              let day = components.day else {
            return 0
        }
        let hour = Double(components.hour ?? 0)
            + Double(components.minute ?? 0) / 60.0
            + Double(components.second ?? 0) / 3600.0

        let a = (14 - month) / 12
        let y = year + 4800 - a
        let m = month + 12 * a - 3

        let jdn = day + (153 * m + 2) / 5 + 365 * y + y / 4 - y / 100 + y / 400 - 32045
        return Double(jdn) + (hour - 12.0) / 24.0
    }

    /// Greenwich Mean Sidereal Time in degrees for a given Julian Date.
    static func gmstDegrees(julianDate jd: Double) -> Double {
        let gmstHours = fmod(
            18.697_374_558 + 24.065_709_824_419_08 * (jd - 2_451_545.0),
            24.0
        )
        let normalized = gmstHours < 0 ? gmstHours + 24.0 : gmstHours
        return normalized * 15.0
    }

    /// Local Sidereal Time in degrees for a given longitude and date.
    static func localSiderealTime(longitude: Double, date: Date) -> Double {
        let jd = julianDate(from: date)
        let gmst = gmstDegrees(julianDate: jd)
        let lst = fmod(gmst + longitude, 360.0)
        return lst < 0 ? lst + 360.0 : lst
    }

    // MARK: - Coordinate Transforms

    /// Convert equatorial coordinates (RA/Dec in degrees) to horizontal
    /// coordinates (altitude/azimuth in degrees) for an observer.
    static func equatorialToHorizontal(
        ra: Double, dec: Double,
        latitude: Double, longitude: Double, date: Date
    ) -> (altitude: Double, azimuth: Double) {
        let lst = localSiderealTime(longitude: longitude, date: date)
        let ha = (lst - ra) * .pi / 180.0

        let latRad = latitude * .pi / 180.0
        let decRad = dec * .pi / 180.0

        let sinAlt = sin(latRad) * sin(decRad) + cos(latRad) * cos(decRad) * cos(ha)
        let altitude = asin(max(-1.0, min(1.0, sinAlt))) * 180.0 / .pi

        let cosAz = (sin(decRad) - sin(latRad) * sinAlt) / (cos(latRad) * cos(asin(sinAlt)))
        let sinAz = -cos(decRad) * sin(ha) / cos(asin(sinAlt))
        let azimuth = atan2(sinAz, cosAz) * 180.0 / .pi
        let normalizedAz = fmod(azimuth + 360.0, 360.0)

        return (altitude: altitude, azimuth: normalizedAz)
    }

    // MARK: - Projection

    /// Gnomonic (tangent plane) projection of a star at (starRA, starDec)
    /// onto a plane centered at (centerRA, centerDec).
    ///
    /// Returns (x, y) in radians on the tangent plane, or nil if the star
    /// is more than 90° from the center (behind the projection plane).
    ///
    /// x increases to the left (east), y increases upward (north).
    static func gnomonicProject(
        starRA: Double, starDec: Double,
        centerRA: Double, centerDec: Double
    ) -> (x: Double, y: Double)? {
        let ra0 = centerRA * .pi / 180.0
        let dec0 = centerDec * .pi / 180.0
        let ra = starRA * .pi / 180.0
        let dec = starDec * .pi / 180.0

        let cosc = sin(dec0) * sin(dec) + cos(dec0) * cos(dec) * cos(ra - ra0)

        // Star is behind the projection center
        guard cosc > 0 else { return nil }

        let x = cos(dec) * sin(ra - ra0) / cosc
        let y = (cos(dec0) * sin(dec) - sin(dec0) * cos(dec) * cos(ra - ra0)) / cosc

        return (x: -x, y: y) // negate x so east is left (matches sky view)
    }

    // MARK: - Galactic Coordinates

    /// Convert galactic coordinates (l, b in degrees) to equatorial (RA, Dec in degrees).
    /// Uses the standard IAU J2000 galactic coordinate system:
    /// - Galactic North Pole: RA = 192.8595°, Dec = 27.1284°
    /// - Ascending node of galactic plane on equator: l_Ω = 32.9319°
    static func galacticToEquatorial(l: Double, b: Double) -> (ra: Double, dec: Double) {
        let lRad = l * .pi / 180.0
        let bRad = b * .pi / 180.0

        // Galactic North Pole in equatorial coords (J2000)
        let raGP: Double = 192.8595 * .pi / 180.0
        let decGP: Double = 27.1284 * .pi / 180.0

        // Longitude of ascending node
        let lOmega: Double = 32.9319 * .pi / 180.0

        // Convert to equatorial Cartesian
        let sinDec = sin(bRad) * sin(decGP)
            + cos(bRad) * cos(decGP) * sin(lRad - lOmega)

        let dec = asin(max(-1.0, min(1.0, sinDec)))

        let yNum = cos(bRad) * cos(lRad - lOmega)
        let xNum = sin(bRad) * cos(decGP)
            - cos(bRad) * sin(decGP) * sin(lRad - lOmega)

        let ra = atan2(yNum, xNum) + raGP

        let raDeg = fmod(ra * 180.0 / .pi + 360.0, 360.0)
        let decDeg = dec * 180.0 / .pi

        return (ra: raDeg, dec: decDeg)
    }
}
