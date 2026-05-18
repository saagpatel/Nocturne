@preconcurrency import AVFoundation
import CoreMotion
import os

/// State machine for the measurement flow.
enum MeasurementState: Sendable {
    case idle
    case requestingPermissions
    case preparingCamera
    case awaitingCapture
    case capturing
    case validating
    case complete(MeasurementRecord)
    case rejected(ValidationFailure)
    case error(MeasurementError)
}

/// Orchestrates the full measurement pipeline:
/// camera → pixel processing → validation → calibration → save.
@Observable
@MainActor
final class MeasurementViewModel {

    private(set) var state: MeasurementState = .idle
    private(set) var previewSession: AVCaptureSession?

    var isValidating: Bool {
        if case .validating = state { return true }
        return false
    }

    let cameraService = CameraService()
    let locationService = LocationService()
    let weatherService = WeatherService()
    let databaseManager: DatabaseManager?

    private let motionManager = CMMotionManager()
    private let validationGate = ValidationGate()
    private let logger = Logger(subsystem: "com.nocturne.app", category: "MeasurementViewModel")

    init() {
        self.databaseManager = try? DatabaseManager.makeDefault()
    }

    // MARK: - Session Management

    /// Request permissions, configure camera, start preview.
    func startSession() async {
        state = .requestingPermissions

        // Camera permission
        let cameraStatus = CameraService.authorizationStatus()
        switch cameraStatus {
        case .denied, .restricted:
            state = .error(.camera(.permissionDenied))
            return
        case .notDetermined:
            let granted = await CameraService.requestAuthorization()
            guard granted else {
                state = .error(.camera(.permissionDenied))
                return
            }
        default:
            break
        }

        // Location permission
        locationService.requestAuthorization()

        // Configure camera
        state = .preparingCamera
        do {
            try await cameraService.configure()
            try await cameraService.startSession()
            previewSession = cameraService.session
            state = .awaitingCapture
        } catch let error as CameraError {
            state = .error(.camera(error))
        } catch {
            state = .error(.camera(.captureFailure(underlying: error.localizedDescription)))
        }

        // Start motion updates
        if motionManager.isDeviceMotionAvailable {
            motionManager.startDeviceMotionUpdates()
        }
    }

    /// Execute the full measurement pipeline.
    func takeMeasurement() async {
        state = .capturing

        do {
            // 1. Start location fetch in parallel
            async let locationResult = locationService.currentLocation()

            // 2. Capture and process frame (inside CameraService actor)
            let capture = try await cameraService.captureAndProcess()
            let rawLuminance = capture.rawLuminance
            let hotFraction = capture.hotPixelFraction

            // 4. Await location
            let location: CLLocation
            do {
                location = try await locationResult
            } catch {
                throw MeasurementError.location(
                    error as? LocationError ?? .locationUnavailable
                )
            }

            // 5. Fetch weather (non-blocking)
            let cloudCover = await weatherService.cloudCoverPercent(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )

            // 6. Read gravity
            let gravity = motionManager.deviceMotion?.gravity
            let gx = gravity?.x ?? 0
            let gy = gravity?.y ?? 0
            let gz = gravity?.z ?? -1.0 // default to face-up if no data

            // 7. Validate
            state = .validating
            let context = ValidationContext(
                location: location,
                date: Date(),
                gravityX: gx,
                gravityY: gy,
                gravityZ: gz,
                hotPixelFraction: hotFraction,
                cloudCoverPct: cloudCover
            )

            let result = validationGate.validate(context: context)

            switch result {
            case .rejected(let failure):
                state = .rejected(failure)
                return

            case .valid(let report):
                // 8. Calibrate
                let model = DeviceInfo.machineIdentifier
                let calibration = CalibrationService.coefficients(for: model)
                let isCalibrated = calibration != nil

                let skyBrightness: Double
                if let cal = calibration {
                    skyBrightness = MeasurementEngine.pixelLuminanceToMagArcsec2(
                        rawLuminance: rawLuminance,
                        calibration: cal
                    )
                } else {
                    // Uncalibrated — store raw estimate
                    skyBrightness = MeasurementEngine.pixelLuminanceToMagArcsec2(
                        rawLuminance: rawLuminance,
                        calibration: CalibrationCoefficients(
                            iphoneModel: model,
                            friendlyName: "Unknown",
                            a: -2.5, b: 11.5, c: -0.003,
                            version: CalibrationConstants.currentVersion
                        )
                    )
                }

                let bortleClass = MeasurementEngine.bortleClass(from: skyBrightness)
                let actualExposure = await cameraService.actualMaxExposure

                // 9. Construct record
                let record = MeasurementRecord(
                    id: UUID().uuidString,
                    measuredAt: Date(),
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    altitudeM: location.altitude,
                    skyBrightness: skyBrightness,
                    rawBrightness: rawLuminance,
                    iphoneModel: model,
                    isoValue: Int(SkyBrightnessConstants.targetISO),
                    exposureS: actualExposure,
                    calibrationVer: CalibrationConstants.currentVersion,
                    cloudCoverPct: report.cloudCoverPct,
                    isCloudy: report.isCloudy,
                    isCalibrated: isCalibrated,
                    isUploaded: false,
                    uploadedAt: nil,
                    deviceTiltDeg: report.deviceTiltDeg,
                    bortleClass: bortleClass
                )

                // 10. Save to database
                if let db = databaseManager {
                    try await db.dbQueue.write { database in
                        try record.insert(database)
                        // Enqueue for upload
                        try database.execute(
                            sql: """
                                INSERT INTO upload_queue (measurement_id, queued_at)
                                VALUES (?, ?)
                                """,
                            arguments: [record.id, Int(Date().timeIntervalSince1970)]
                        )
                    }
                    logger.info("Measurement saved: \(skyBrightness) mag/arcsec², Bortle \(bortleClass)")
                }

                state = .complete(record)
            }
        } catch let error as MeasurementError {
            state = .error(error)
        } catch let error as CameraError {
            state = .error(.camera(error))
        } catch {
            state = .error(.camera(.captureFailure(underlying: error.localizedDescription)))
        }
    }

    /// Reset to awaiting capture state.
    func reset() {
        state = .awaitingCapture
    }

    /// Stop the session and return to idle.
    func dismiss() async {
        await cameraService.stopSession()
        motionManager.stopDeviceMotionUpdates()
        previewSession = nil
        state = .idle
    }
}