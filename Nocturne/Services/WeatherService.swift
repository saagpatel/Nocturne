import Foundation
import os

/// Fetches cloud cover data from the Open-Meteo API.
/// Returns nil on any failure — never throws. Measurements remain valid
/// without weather data (tagged as `weather_unknown`).
actor WeatherService {

    private let session: URLSession
    private let logger = Logger(subsystem: "com.nocturne.app", category: "WeatherService")

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Fetch cloud cover percentage (0–100) for the given location at the current hour.
    /// Returns nil on network error, parse failure, or missing data.
    func cloudCoverPercent(latitude: Double, longitude: Double) async -> Int? {
        let urlString = "\(WeatherConstants.openMeteoBaseURL)"
            + "?latitude=\(latitude)"
            + "&longitude=\(longitude)"
            + "&hourly=cloudcover"
            + "&forecast_days=1"

        guard let url = URL(string: urlString) else {
            logger.error("Invalid Open-Meteo URL")
            return nil
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = WeatherConstants.requestTimeoutSeconds

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                logger.warning("Open-Meteo returned non-200 status")
                return nil
            }

            let decoded = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
            return extractCurrentHourCloudCover(from: decoded)
        } catch {
            logger.warning("Weather fetch failed: \(error.localizedDescription)")
            return nil
        }
    }

    /// Find the cloud cover entry closest to the current hour.
    private func extractCurrentHourCloudCover(from response: OpenMeteoResponse) -> Int? {
        let times = response.hourly.time
        let covers = response.hourly.cloudcover

        guard !times.isEmpty, times.count == covers.count else { return nil }

        // Open-Meteo time format: "yyyy-MM-dd'T'HH:mm"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        formatter.timeZone = TimeZone(identifier: "UTC")

        let now = Date()
        var bestIndex = 0
        var bestDistance: TimeInterval = .infinity

        for (index, timeString) in times.enumerated() {
            guard let entryDate = formatter.date(from: timeString) else { continue }
            let distance = abs(entryDate.timeIntervalSince(now))
            if distance < bestDistance {
                bestDistance = distance
                bestIndex = index
            }
        }

        guard bestIndex < covers.count else { return nil }
        return covers[bestIndex]
    }
}

// MARK: - Open-Meteo Response

struct OpenMeteoResponse: Codable, Sendable {
    let hourly: Hourly

    struct Hourly: Codable, Sendable {
        let time: [String]
        let cloudcover: [Int]
    }
}
