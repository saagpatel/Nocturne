import CoreLocation
import os

/// Single-shot location service using iOS 17+ async location updates.
/// Follows the Wavelength LocationMonitor pattern but is simpler:
/// get one fix and stop.
@Observable
@MainActor
final class LocationService {

    private(set) var authorizationStatus: CLAuthorizationStatus

    private let locationManager = CLLocationManager()
    private let logger = Logger(subsystem: "com.nocturne.app", category: "LocationService")

    init() {
        self.authorizationStatus = locationManager.authorizationStatus
    }

    /// Request when-in-use location authorization.
    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
        authorizationStatus = locationManager.authorizationStatus
    }

    /// Get a single location fix with acceptable accuracy.
    /// Uses `CLLocationUpdate.liveUpdates()` (iOS 17+).
    /// Throws `LocationError.timeout` after `LocationConstants.locationTimeoutSeconds`.
    func currentLocation() async throws -> CLLocation {
        let status = locationManager.authorizationStatus
        switch status {
        case .denied:
            throw LocationError.permissionDenied
        case .restricted:
            throw LocationError.permissionRestricted
        case .notDetermined:
            requestAuthorization()
        default:
            break
        }

        return try await withThrowingTaskGroup(of: CLLocation.self) { group in
            // Location stream
            group.addTask {
                let updates = CLLocationUpdate.liveUpdates()
                for try await update in updates {
                    guard let location = update.location else { continue }
                    if location.horizontalAccuracy >= 0,
                       location.horizontalAccuracy < LocationConstants.minimumAccuracyMeters {
                        return location
                    }
                }
                throw LocationError.locationUnavailable
            }

            // Timeout
            group.addTask {
                try await Task.sleep(
                    for: .seconds(LocationConstants.locationTimeoutSeconds)
                )
                throw LocationError.timeout
            }

            // First to complete wins
            guard let result = try await group.next() else {
                throw LocationError.locationUnavailable
            }
            group.cancelAll()
            return result
        }
    }
}
