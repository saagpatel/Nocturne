import SpriteKit
import SwiftUI

struct ComparisonView: View {
    @Bindable var viewModel: ComparisonViewModel
    @State private var fullScreenPanel: Panel?
    @State private var shareImage: UIImage?
    @State private var showShareSheet = false

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
                .accessibilityLabel("Share comparison")
                .accessibilityHint("Share a composite image of your sky versus a pristine sky")
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
        .sheet(isPresented: $showShareSheet) {
            if let shareImage {
                ShareSheet(items: [shareImage])
            }
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(starCount) stars visible")
        .accessibilityHint("Tap to view full screen")
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(unit)")
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
                    .accessibilityLabel("Close full screen view")
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
        guard let userScene = viewModel.userScene,
              let pristineScene = viewModel.pristineScene else { return }

        let sceneSize = userScene.size
        let panelWidth = sceneSize.width
        let panelHeight = sceneSize.height
        let gap: CGFloat = 2
        let labelHeight: CGFloat = 40
        let statBarHeight: CGFloat = 60
        let compositeWidth = panelWidth * 2 + gap
        let compositeHeight = panelHeight + labelHeight + statBarHeight

        // Render each scene to UIImage via offscreen SKView
        let skView = SKView(frame: CGRect(origin: .zero, size: sceneSize))
        skView.allowsTransparency = false

        let userTexture = skView.texture(from: userScene)
        let pristineTexture = skView.texture(from: pristineScene)

        guard let userCGImage = userTexture?.cgImage(),
              let pristineCGImage = pristineTexture?.cgImage() else { return }

        let userImage = UIImage(cgImage: userCGImage)
        let pristineImage = UIImage(cgImage: pristineCGImage)

        // Composite both panels with labels and stats
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: compositeWidth, height: compositeHeight)
        )

        let composite = renderer.image { ctx in
            // Background
            UIColor.black.setFill()
            ctx.fill(CGRect(origin: .zero, size: CGSize(width: compositeWidth, height: compositeHeight)))

            // Draw star panels
            userImage.draw(in: CGRect(x: 0, y: 0, width: panelWidth, height: panelHeight))
            pristineImage.draw(in: CGRect(x: panelWidth + gap, y: 0, width: panelWidth, height: panelHeight))

            // Labels
            let labelAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13, weight: .semibold),
                .foregroundColor: UIColor.white,
            ]
            let userLabel = "Your Sky" as NSString
            let pristineLabel = "What You're Missing" as NSString
            let userLabelSize = userLabel.size(withAttributes: labelAttrs)
            let pristineLabelSize = pristineLabel.size(withAttributes: labelAttrs)

            userLabel.draw(
                at: CGPoint(
                    x: (panelWidth - userLabelSize.width) / 2,
                    y: panelHeight + (labelHeight - userLabelSize.height) / 2
                ),
                withAttributes: labelAttrs
            )
            pristineLabel.draw(
                at: CGPoint(
                    x: panelWidth + gap + (panelWidth - pristineLabelSize.width) / 2,
                    y: panelHeight + (labelHeight - pristineLabelSize.height) / 2
                ),
                withAttributes: labelAttrs
            )

            // Stat bar
            let statY = panelHeight + labelHeight
            UIColor(white: 0.08, alpha: 1.0).setFill()
            ctx.fill(CGRect(x: 0, y: statY, width: compositeWidth, height: statBarHeight))

            let statAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .heavy),
                .foregroundColor: UIColor.white,
            ]
            let unitAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .regular),
                .foregroundColor: UIColor.white.withAlphaComponent(0.5),
            ]

            let brightness = String(format: "%.1f mag/arcsec²", viewModel.skyBrightness)
            let bortle = "Bortle Class \(viewModel.bortleClass)"
            let stats = "\(brightness)  |  \(bortle)" as NSString
            let statsSize = stats.size(withAttributes: statAttrs)
            stats.draw(
                at: CGPoint(
                    x: (compositeWidth - statsSize.width) / 2,
                    y: statY + 12
                ),
                withAttributes: statAttrs
            )

            let watermark = "Measured with Nocturne" as NSString
            let watermarkSize = watermark.size(withAttributes: unitAttrs)
            watermark.draw(
                at: CGPoint(
                    x: (compositeWidth - watermarkSize.width) / 2,
                    y: statY + statBarHeight - watermarkSize.height - 8
                ),
                withAttributes: unitAttrs
            )
        }

        shareImage = composite
        showShareSheet = true
    }
}

// MARK: - Share Sheet

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
