import SwiftUI
import AVFoundation

struct GestureCameraView: View {
    @StateObject private var gestureCameraViewModel = GestureCameraViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            switch gestureCameraViewModel.appState {
            case .detecting:
                ActiveCameraView(
                    session: gestureCameraViewModel.session,
                    permissionGranted: gestureCameraViewModel.permissionGranted
                )
            case .success:
                StatusFeedbackSectionView(
                    title: "送信完了しました",
                    subtitle: "3秒後に閉じます...",
                    iconName: "checkmark.circle.fill",
                    color: .green
                )
            case .waiting:
                EmptyView()
            }
        }
        .frame(width: 320, height: 240)
        .background(.regularMaterial)
        .onChange(of: gestureCameraViewModel.appState) { oldValue, newValue in
            if newValue == .waiting {
                dismiss()
            }
        }
    }
}


struct ActiveCameraView: View {
    let session: AVCaptureSession
    let permissionGranted: Bool
    
    var body: some View {
        VStack {
            if permissionGranted {
                ZStack(alignment: .bottom) {
                    CameraPreviewView(session: session)
                        .cornerRadius(12)
                        .padding(10)
                    
                    Text("カメラに向かってジェスチャー🫶をしてください")
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                        .padding(.bottom, 20)
                }
            } else {
                VStack {
                    Image(systemName: "video.slash")
                        .font(.largeTitle)
                    Text("カメラの権限が必要です")
                }
            }
        }
    }
}

// MARK: - AVCaptureVideoPreviewLayer を SwiftUI で使うためのラッパー
struct CameraPreviewView: NSViewRepresentable {
    let session: AVCaptureSession
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        
        if previewLayer.connection?.isVideoMirroringSupported == true {
            previewLayer.connection?.automaticallyAdjustsVideoMirroring = false
            previewLayer.connection?.isVideoMirrored = true
        }
        
        view.layer = previewLayer
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if let layer = nsView.layer as? AVCaptureVideoPreviewLayer {
            layer.frame = nsView.bounds
        }
    }
}
