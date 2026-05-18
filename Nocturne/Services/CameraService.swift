@preconcurrency import AVFoundation
import os

/// Manages camera capture for sky brightness measurement.
/// Uses AVCapturePhotoOutput for single-frame capture with manual exposure.
actor CameraService {

    nonisolated(unsafe) let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "com.nocturne.camera")
    private let logger = Logger(subsystem: "com.nocturne.app", category: "CameraService")

    private var captureDevice: AVCaptureDevice?
    private(set) var actualMaxExposure: Double = 0
    private(set) var isSessionRunning = false

    // MARK: - Authorization

    nonisolated static func authorizationStatus() -> AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }

    nonisolated static func requestAuthorization() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .video)
    }

    // MARK: - Configuration

    /// Configure the capture session with the wide-angle back camera.
    /// Sets manual exposure: ISO 1600, maximum available exposure duration.
    func configure() async throws {
        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        ) else {
            throw CameraError.deviceNotAvailable
        }

        captureDevice = device
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        session.sessionPreset = .photo

        // Add input
        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else {
            throw CameraError.deviceNotAvailable
        }
        session.addInput(input)

        // Add photo output
        guard session.canAddOutput(photoOutput) else {
            throw CameraError.deviceNotAvailable
        }
        session.addOutput(photoOutput)

        // Configure manual exposure
        try device.lockForConfiguration()
        defer { device.unlockForConfiguration() }

        let maxDuration = device.activeFormat.maxExposureDuration
        let maxSeconds = CMTimeGetSeconds(maxDuration)
        actualMaxExposure = min(maxSeconds, SkyBrightnessConstants.targetExposure)

        let targetDuration = CMTimeMakeWithSeconds(actualMaxExposure, preferredTimescale: 1_000_000)
        let targetISO = min(SkyBrightnessConstants.targetISO, device.activeFormat.maxISO)

        if device.isExposureModeSupported(.custom) {
            device.setExposureModeCustom(
                duration: targetDuration,
                iso: targetISO,
                completionHandler: nil
            )
        } else if device.isExposureModeSupported(.locked) {
            device.exposureMode = .locked
        }

        let configuredExposure = actualMaxExposure
        logger.info("Camera configured: ISO=\(targetISO), exposure=\(configuredExposure)s, deviceMax=\(maxSeconds)s")
    }

    // MARK: - Session Lifecycle

    func startSession() async throws {
        guard !session.isRunning else { return }
        session.startRunning()
        isSessionRunning = session.isRunning
    }

    func stopSession() async {
        guard session.isRunning else { return }
        session.stopRunning()
        isSessionRunning = false
    }

    // MARK: - Capture

    /// Capture a single frame, process it, and return luminance data.
    /// Uses AVCapturePhotoOutput with the device's locked manual exposure.
    /// Processing happens inside the actor to avoid sending CVPixelBuffer across isolation.
    func captureAndProcess() async throws -> CaptureResult {
        let pixelBuffer = try await captureRawFrame()
        let luminance = MeasurementEngine.averageLuminance(from: pixelBuffer)
        let hotFraction = MeasurementEngine.hotPixelFraction(in: pixelBuffer)
        return CaptureResult(rawLuminance: luminance, hotPixelFraction: hotFraction)
    }

    /// Capture a single raw frame. Internal use only.
    private func captureRawFrame() async throws -> CVPixelBuffer {
        guard session.isRunning else {
            throw CameraError.sessionNotRunning
        }

        let settings = AVCapturePhotoSettings()

        // Request BGRA format if available
        if let availableFormats = settings.availablePreviewPhotoPixelFormatTypes
            .first(where: { $0 == kCVPixelFormatType_32BGRA }) {
            settings.previewPhotoFormat = [
                kCVPixelBufferPixelFormatTypeKey as String: availableFormats
            ]
        }

        return try await withCheckedThrowingContinuation { continuation in
            let delegate = PhotoCaptureDelegate(continuation: continuation)
            photoOutput.capturePhoto(with: settings, delegate: delegate)
        }
    }

    // MARK: - Preview

    /// Creates a preview layer bound to the capture session.
    @MainActor
    func makePreviewLayer() -> AVCaptureVideoPreviewLayer {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        return layer
    }
}

/// Results from a camera capture, processed within the CameraService actor.
struct CaptureResult: Sendable {
    let rawLuminance: Double       // cd/m²
    let hotPixelFraction: Double   // [0.0, 1.0]
}

// MARK: - Photo Capture Delegate

private final class PhotoCaptureDelegate: NSObject,
    AVCapturePhotoCaptureDelegate, @unchecked Sendable {

    private var continuation: CheckedContinuation<CVPixelBuffer, Error>?

    init(continuation: CheckedContinuation<CVPixelBuffer, Error>) {
        self.continuation = continuation
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard let continuation else { return }
        self.continuation = nil

        if let error {
            continuation.resume(throwing: CameraError.captureFailure(underlying: error.localizedDescription))
            return
        }

        guard let buffer = photo.pixelBuffer else {
            continuation.resume(throwing: CameraError.captureFailure(underlying: "No pixel buffer in photo"))
            return
        }

        // CVPixelBuffer is not Sendable but we're transferring sole ownership
        nonisolated(unsafe) let pixelBuffer = buffer
        continuation.resume(returning: pixelBuffer)
    }
}
