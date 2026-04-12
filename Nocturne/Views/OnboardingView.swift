import SwiftUI

/// Three-step first-launch tutorial introducing users to Nocturne.
struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    @State private var currentStep = 0

    private let steps: [OnboardingStep] = [
        OnboardingStep(
            icon: "moon.stars.fill",
            title: "Nocturne measures your sky's darkness",
            description: "Using your iPhone's camera, Nocturne calculates how much light pollution washes out the stars above you and converts it to a standardized Bortle scale reading."
        ),
        OnboardingStep(
            icon: "iphone.rear.camera",
            title: "Point at the sky, hold still, and measure",
            description: "Find a clear view of the night sky, hold your phone pointed straight up, and tap Measure. Nocturne captures a calibrated exposure and validates the reading automatically."
        ),
        OnboardingStep(
            icon: "sparkles",
            title: "See what you're missing compared to a pristine sky",
            description: "Nocturne renders the stars you can see side-by-side with what a perfectly dark sky would reveal — thousands of stars, the Milky Way, and deep-sky objects hidden by light pollution."
        ),
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Icon
                Image(systemName: steps[currentStep].icon)
                    .font(.system(size: 72))
                    .foregroundStyle(Color.amber)
                    .padding(.bottom, 40)
                    .accessibilityHidden(true)

                // Title
                Text(steps[currentStep].title)
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 16)

                // Description
                Text(steps[currentStep].description)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)

                Spacer()

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentStep ? Color.amber : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 32)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Step \(currentStep + 1) of \(steps.count)")

                // Action button
                Button {
                    if currentStep < steps.count - 1 {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep += 1
                        }
                    } else {
                        hasSeenOnboarding = true
                    }
                } label: {
                    Text(currentStep < steps.count - 1 ? "Continue" : "Get Started")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.amber)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .accessibilityLabel(currentStep < steps.count - 1 ? "Continue to next step" : "Start using Nocturne")
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

                // Skip button (not on last step)
                if currentStep < steps.count - 1 {
                    Button("Skip") {
                        hasSeenOnboarding = true
                    }
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.white.opacity(0.5))
                    .accessibilityLabel("Skip onboarding")
                    .accessibilityHint("Jump directly to the app")
                }

                Spacer()
                    .frame(height: 32)
            }
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Step Model

private struct OnboardingStep {
    let icon: String
    let title: String
    let description: String
}
