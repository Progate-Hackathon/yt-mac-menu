import SwiftUI
import AVFoundation


struct GestureCameraView: View {
    @ObservedObject var gestureCameraViewModel: GestureCameraViewModel
    
    var body: some View {
        ZStack {
            switch gestureCameraViewModel.appState {
            case .detecting:
                ActiveCameraView(gestureCameraViewModel: gestureCameraViewModel)
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
    }
}


struct ActiveCameraView: View {
    @ObservedObject var gestureCameraViewModel: GestureCameraViewModel
    
    var body: some View {
        VStack {
            if gestureCameraViewModel.permissionGranted {
                ZStack(alignment: .bottom) {
                    CameraPreviewView(session: gestureCameraViewModel.session)
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
        // ウィンドウのリサイズに追従させる
        previewLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        
        view.layer = previewLayer
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if let layer = nsView.layer as? AVCaptureVideoPreviewLayer {
            layer.frame = nsView.bounds
        }
    }
}
