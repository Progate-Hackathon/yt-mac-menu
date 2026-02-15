import SwiftUI
import AVFoundation

struct GestureCameraView: View {
    @StateObject private var gestureCameraViewModel: GestureCameraViewModel
    
    init() {
        let container = DependencyContainer.shared
        let cameraUseCase = container.makeCameraManagementUseCase()
        let gestureUseCase = container.makeGestureDetectionUseCase()
        let commitDataModelUseCase = container.makeCommitDataModelUseCase()
        _gestureCameraViewModel = StateObject(wrappedValue: GestureCameraViewModel(
            cameraUseCase: cameraUseCase,
            gestureUseCase: gestureUseCase,
            commitDataModelUseCase: commitDataModelUseCase
            
        ))
    }
    
    var body: some View {
        ZStack {
            switch gestureCameraViewModel.appState {
            case .detecting:
                    ActiveCameraView(session: gestureCameraViewModel.session, detectedHandCount: $gestureCameraViewModel.detectedHandCount)
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
            case .error(let error):
                ErrorStateView(error: error)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
    }
}


struct ActiveCameraView: View {
    let session: AVCaptureSession
    @State private var triggerUpdate = false
    @Binding var detectedHandCount: Int
    
    var body: some View {
        ZStack {
            // Camera
            CameraPreviewView(session: session, triggerUpdate: triggerUpdate)
                .ignoresSafeArea()
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        triggerUpdate.toggle()
                    }
                }
            
            // Overlay UI
            VStack {
                Spacer()
                
                statusCard
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: detectedHandCount)
            }
        }
    }
    
    // MARK: - Status Card
    
    private var statusCard: some View {
        let (text, icon, color) = statusInfo
        
        return HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
            
            Text(text)
                .font(.headline)
                .multilineTextAlignment(.leading)
        }
        .foregroundColor(.white)
        .padding()
        .frame(maxWidth: .infinity)
        .frame(height: 30)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(color.opacity(0.85))
        )
    }
    
    private var statusInfo: (String, String, Color) {
        switch detectedHandCount {
        case 0:
            return ("手をカメラの前に出してください",
                    "camera.viewfinder",
                    .red)
            
        case 1:
            return ("もう片方の手を追加してください",
                    "hand.raised.fill",
                    .orange)
            
        default:
            return ("準備OK！🫶 ジェスチャーを作ってください",
                    "hands.sparkles.fill",
                    .green)
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
