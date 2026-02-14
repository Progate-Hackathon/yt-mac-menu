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
    @State private var triggerUpdate = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            CameraPreviewView(session: session, triggerUpdate: triggerUpdate)
                .cornerRadius(12)
                .padding(10)
                .onAppear {
                    // セッション開始を待ってからミラーリングをトリガー
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        triggerUpdate.toggle()
                    }
                }
            
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
    let triggerUpdate: Bool
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        
        view.layer = previewLayer
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if let layer = nsView.layer as? AVCaptureVideoPreviewLayer {
            layer.frame = nsView.bounds
            
            // セッションが実行中かつミラーリングが未設定の場合に設定
            if session.isRunning,
               let connection = layer.connection,
               connection.isVideoMirroringSupported {
                if !connection.isVideoMirrored {
                    connection.automaticallyAdjustsVideoMirroring = false
                    connection.isVideoMirrored = true
                    print("カメラミラーリング有効化: \(connection.isVideoMirrored)")
                }
            }
        }
    }
}
