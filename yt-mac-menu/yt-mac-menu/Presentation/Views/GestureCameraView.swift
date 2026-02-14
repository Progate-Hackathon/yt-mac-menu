import SwiftUI
import AVFoundation

struct GestureCameraView: View {
    @StateObject private var gestureCameraViewModel: GestureCameraViewModel
    
    init() {
        let container = DependencyContainer.shared
        let cameraUseCase = container.makeCameraManagementUseCase()
        let gestureUseCase = container.makeGestureDetectionUseCase()
        _gestureCameraViewModel = StateObject(wrappedValue: GestureCameraViewModel(
            cameraUseCase: cameraUseCase,
            gestureUseCase: gestureUseCase
        ))
    }
    
    var body: some View {
        ZStack {
            switch gestureCameraViewModel.appState {
            case .detecting:
                ActiveCameraView(session: gestureCameraViewModel.session)
            case .success:
                StatusFeedbackSectionView(
                    title: "送信完了しました",
                    subtitle: "3秒後に閉じます...",
                    iconName: "checkmark.circle.fill",
                    color: .green
                )
            case .waiting:
                StatusFeedbackSectionView(
                    title: "読み込み中です",
                    subtitle: "しばらくお待ちください...",
                    iconName: "hourglass",
                    color: .gray
                )
            case .unauthorized:
                VStack {
                    Image(systemName: "video.slash")
                        .font(.largeTitle)
                    Text("カメラの権限が必要です")
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
    }
}


struct ActiveCameraView: View {
    let session: AVCaptureSession
    
    var body: some View {
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
        
        view.layer = previewLayer
        
        // ミラーリングを遅延設定（セッションが開始されてから）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let connection = previewLayer.connection,
               connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = true
                print("カメラミラーリング有効化: \(connection.isVideoMirrored)")
            }
        }
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if let layer = nsView.layer as? AVCaptureVideoPreviewLayer {
            layer.frame = nsView.bounds
            
            // updateでもミラーリングを確認
            if let connection = layer.connection,
               connection.isVideoMirroringSupported,
               !connection.isVideoMirrored {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = true
                print("カメラミラーリング再設定")
            }
        }
    }
}
