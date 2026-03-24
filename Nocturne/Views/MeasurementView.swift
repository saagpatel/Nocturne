import SwiftUI

struct MeasurementView: View {
    @Bindable var viewModel: MeasurementViewModel
    @Binding var navigationPath: NavigationPath

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch viewModel.state {
            case .idle, .requestingPermissions, .preparingCamera:
                startupView

            case .awaitingCapture:
                captureReadyView

            case .capturing, .validating:
                capturingView

            case .complete(let record):
                resultView(record: record)

            case .rejected(let failure):
                rejectionView(failure: failure)

            case .error(let error):
                errorView(error: error)
            }
        }
        .preferredColorScheme(.dark)
        .task {
            if case .idle = viewModel.state {
                await viewModel.startSession()
            }
        }
    }

    // MARK: - Startup

    private var startupView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .controlSize(.large)
                .tint(Color.amber)

            Text(startupMessage)
                .font(.system(size: 16, weight: .light))
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    private var startupMessage: String {
        switch viewModel.state {
        case .requestingPermissions: "Requesting permissions..."
        case .preparingCamera: "Preparing camera..."
        default: "Starting..."
        }
    }

    // MARK: - Capture Ready

    private var captureReadyView: some View {
        ZStack {
            // Camera preview
            if let session = viewModel.previewSession {
                CameraPreview(session: session)
                    .ignoresSafeArea()
            }

            // Overlay
            VStack {
                Spacer()

                // Instructions
                Text("Point toward the sky")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.bottom, 16)

                // Measure button
                Button {
                    Task { await viewModel.takeMeasurement() }
                } label: {
                    Text("Measure Sky")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.amber)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }

    // MARK: - Capturing

    private var capturingView: some View {
        ZStack {
            if let session = viewModel.previewSession {
                CameraPreview(session: session)
                    .ignoresSafeArea()
            }

            VStack(spacing: 16) {
                // Pulsing ring
                Circle()
                    .stroke(Color.amber.opacity(0.6), lineWidth: 3)
                    .frame(width: 120, height: 120)

                Text(viewModel.isValidating ? "Validating..." : "Capturing...")
                    .font(.system(size: 16, weight: .light))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }

    // MARK: - Result

    private func resultView(record: MeasurementRecord) -> some View {
        ZStack {
            if let session = viewModel.previewSession {
                CameraPreview(session: session)
                    .ignoresSafeArea()
                    .opacity(0.3)
            }

            VStack(spacing: 0) {
                Spacer()

                // Result card
                VStack(spacing: 20) {
                    // Sky brightness
                    VStack(spacing: 4) {
                        Text(String(format: "%.1f", record.skyBrightness))
                            .font(.system(size: 48, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)

                        Text("mag/arcsec²")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(.white.opacity(0.5))
                    }

                    // Bortle badge
                    BortleBadge(bortleClass: record.bortleClass)

                    // Meta row
                    HStack(spacing: 24) {
                        metaItem(
                            label: "Calibrated",
                            value: record.isCalibrated ? "Yes" : "No",
                            color: record.isCalibrated ? .green : .orange
                        )

                        if let cloud = record.cloudCoverPct {
                            metaItem(
                                label: "Cloud Cover",
                                value: "\(cloud)%",
                                color: record.isCloudy ? .orange : .green
                            )
                        } else {
                            metaItem(label: "Weather", value: "N/A", color: .gray)
                        }
                    }

                    // Actions
                    Button("See Your Sky") {
                        Task {
                            await viewModel.dismiss()
                            navigationPath.append(record)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button("Measure Again") {
                        viewModel.reset()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(24)
                .background(Color(white: 0.11))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
    }

    // MARK: - Rejection

    private func rejectionView(failure: ValidationFailure) -> some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.softRed)

                Text("Measurement Rejected")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)

                Text(rejectionMessage(for: failure))
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)

                Button("Try Again") {
                    viewModel.reset()
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 8)
            }
            .padding(32)
            .background(Color(white: 0.11))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    private func rejectionMessage(for failure: ValidationFailure) -> String {
        switch failure {
        case .notDarkEnough(let alt):
            "The sky is too bright (sun at \(String(format: "%.0f", alt))°). Wait until after sunset."
        case .deviceTilt(let deg):
            "Your phone is tilted \(String(format: "%.0f", deg))° from vertical. Point it straight up at the sky."
        case .lightSourceInFrame(let frac):
            "A bright light source was detected (\(String(format: "%.0f", frac * 100))% saturated pixels). Move away from streetlights."
        }
    }

    // MARK: - Error

    private func errorView(error: MeasurementError) -> some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.softRed)

                Text("Something went wrong")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)

                Text(errorMessage(for: error))
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)

                Button("Try Again") {
                    Task { await viewModel.startSession() }
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 8)
            }
            .padding(32)
            .background(Color(white: 0.11))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    private func errorMessage(for error: MeasurementError) -> String {
        switch error {
        case .camera(.permissionDenied):
            "Camera access is required. Please enable it in Settings."
        case .camera(.deviceNotAvailable):
            "No suitable camera found on this device."
        case .location(.permissionDenied):
            "Location access is required. Please enable it in Settings."
        case .location(.timeout):
            "Could not determine your location. Please try again."
        default:
            "An unexpected error occurred. Please try again."
        }
    }

    // MARK: - Helpers

    private func metaItem(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.white.opacity(0.5))
        }
    }
}

// MARK: - Button Styles

private struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.amber)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

private struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.white.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

// MARK: - Theme Colors

extension Color {
    static let amber = Color(red: 0.961, green: 0.651, blue: 0.137)
    static let softRed = Color(red: 1.0, green: 0.420, blue: 0.420)
    static let softGreen = Color(red: 0.412, green: 0.859, blue: 0.486)
}
