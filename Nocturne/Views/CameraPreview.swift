import AVFoundation
import SwiftUI

/// UIViewRepresentable wrapper for AVCaptureVideoPreviewLayer.
/// Uses a custom UIView subclass with `layerClass` override so the preview
/// layer automatically resizes with Auto Layout.
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        view.backgroundColor = .black
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        uiView.previewLayer.session = session
    }

    final class PreviewUIView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

        var previewLayer: AVCaptureVideoPreviewLayer {
            // This is safe because layerClass guarantees the type
            layer as! AVCaptureVideoPreviewLayer
        }
    }
}
