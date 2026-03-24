import SpriteKit
import SwiftUI

struct ComparisonView: View {
    @Bindable var viewModel: ComparisonViewModel
    @State private var fullScreenPanel: Panel?

    enum Panel: Identifiable {
        case user, pristine
        var id: Self { self }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.error {
                errorView(message: error)
            } else {
                contentView
            }
        }
        .navigationTitle("Sky Comparison")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    shareComposite()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.white)
                }
            }
        }
        .task {
            await viewModel.loadScenes(
                sceneSize: CGSize(width: 300, height: 500)
            )
        }
        .fullScreenCover(item: $fullScreenPanel) { panel in
            fullScreenView(for: panel)
        }
    }

    // MARK: - Content

    private var contentView: some View {
        VStack(spacing: 0) {
            // Star field panels
            HStack(spacing: 2) {
                starPanel(
                    scene: viewModel.userScene,
                    label: "Your Sky",
                    starCount: viewModel.userStarCount,
                    panel: .user
                )
                starPanel(
                    scene: viewModel.pristineScene,
                    label: "What You're Missing",
                    starCount: viewModel.pristineStarCount,
                    panel: .pristine
                )
            }

            // Stat bar
            statBar
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                .background(Color(white: 0.08))
        }
    }

    private func starPanel(
        scene: SkyScene?,
        label: String,
        starCount: Int,
        panel: Panel
    ) -> some View {
        VStack(spacing: 8) {
            if let scene {
                SpriteView(scene: scene, options: [.ignoresSiblingOrder])
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onTapGesture { fullScreenPanel = panel }
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(white: 0.05))
            }

            VStack(spacing: 2) {
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)

                Text("\(starCount) stars")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Stat Bar

    private var statBar: some View {
        HStack(spacing: 0) {
            statItem(
                value: String(format: "%.1f", viewModel.skyBrightness),
                unit: "mag/arcsec²"
            )

            Divider()
                .frame(height: 32)
                .background(Color.white.opacity(0.2))

            BortleBadge(bortleClass: viewModel.bortleClass)
                .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 32)
                .background(Color.white.opacity(0.2))

            statItem(
                value: String(format: "%.1f", viewModel.limitingMagnitude),
                unit: "limiting mag"
            )
        }
    }

    private func statItem(value: String, unit: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            Text(unit)
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Full Screen

    private func fullScreenView(for panel: Panel) -> some View {
        ZStack {
            Color.black.ignoresSafeArea()

            let scene: SkyScene? = panel == .user
                ? viewModel.userScene
                : viewModel.pristineScene

            if let scene {
                SpriteView(scene: scene, options: [.ignoresSiblingOrder])
                    .ignoresSafeArea()
            }

            VStack {
                HStack {
                    Spacer()
                    Button {
                        fullScreenPanel = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(16)
                }
                Spacer()
            }
        }
    }

    // MARK: - Loading / Error

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
                .tint(Color.amber)
            Text("Loading star catalog...")
                .font(.system(size: 16, weight: .light))
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.softRed)
            Text(message)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    // MARK: - Share

    private func shareComposite() {
        // TODO: Implement composite screenshot via SKView.texture(from:)
        // Deferred to polish — requires capturing both scenes to UIImage
    }
}
