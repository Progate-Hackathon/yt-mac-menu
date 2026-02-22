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
            if let feedback = gestureCameraViewModel.gestureCameraViewState.feedbackRepresentation {
                // All feedback states use the same component with different data
                StatusFeedbackSectionView(
                    title: feedback.title,
                    subtitle: feedback.subtitle,
                    iconName: feedback.iconName,
                    color: feedback.color
                )
            } else {
                // Custom UI for special states
                switch gestureCameraViewModel.gestureCameraViewState {
                case .detectingGesture:
                    ZStack {
                        ActiveCameraView(
                            session: gestureCameraViewModel.session,
                            detectedHandCount: $gestureCameraViewModel.detectedHandCount,
                            gestureMode: gestureCameraViewModel.detectedHandCount >= 2 ? .twoHands : .oneHand

                        )
                        
                        // カウントダウンオーバーレイ
                        if let countdown = gestureCameraViewModel.currentCountdown {
                            CountdownOverlayView(countdown: countdown, totalSeconds: 1.5)
                                .transition(.scale.combined(with: .opacity))
                                .animation(.easeInOut(duration: 0.3), value: countdown.secondsRemaining)
                        }
                    }
                    
                case .commandResult(let result):
                    CommandResultView(result: result) {
                        FloatingWindowController.shared.close()
                    }
                    
                case .error(let error):
                    ErrorStateView(error: error)
                    
                case .unauthorized:
                    PermissionDeniedView(
                        permissionType: .camera,
                        onOpenSettings: {
                            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera") {
                                NSWorkspace.shared.open(url)
                            }
                        },
                        onClose: {
                            FloatingWindowController.shared.close()
                        }
                    )
                    
                case .waitingSnap:
                    // No UI needed - window not visible yet
                    EmptyView()
                    
                default:
                    EmptyView()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
    }
}

enum GestureMode {
    case oneHand
    case twoHands
}

struct ActiveCameraView: View {
    let session: AVCaptureSession
    @State private var triggerUpdate = false
    @Binding var detectedHandCount: Int
    var gestureMode: GestureMode   // ← 追加
    
    var body: some View {
        ZStack {
            CameraPreviewView(session: session, triggerUpdate: triggerUpdate)
                .ignoresSafeArea()
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        triggerUpdate.toggle()
                    }
                }
            
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
        switch gestureMode {
            
        case .oneHand:
            switch detectedHandCount {
            case 0:
                return ("手をカメラの前に出してください",
                        "camera.viewfinder",
                        .red)
                    
            case 1:
                return ("👍 または ✌️ を作ってください",
                        "hand.raised.fill",
                        .green)
                    
            default:
                return ("1本モードです ✋ 片手だけ使ってください",
                        "exclamationmark.triangle.fill",
                        .orange)
            }
            
        case .twoHands:
            switch detectedHandCount {
            case 0:
                return ("両手をカメラの前に出してください",
                        "camera.viewfinder",
                        .red)
                    
            case 1:
                return ("もう片方の手を追加してください",
                        "hands.clap.fill",
                        .orange)
                    
            default:
                return ("🫶 を作ってください",
                        "hands.clap.fill",
                        .green)
            }
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

// MARK: - Countdown Overlay

struct CountdownOverlayView: View {
    let countdown: GestureCountdown
    let totalSeconds: Double
    
    private var progress: Double {
        countdown.secondsRemaining / totalSeconds
    }
    
    var body: some View {
        VStack(spacing: 20) {
            
            ZStack {
                
                // 背景リング
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 12)
                
                // 進捗リング（Arc）
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Color.white,
                        style: StrokeStyle(
                            lineWidth: 12,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: progress)
                
                // 中央の秒数
                Text(countdown.gestureType.emoji)
                    .font(.system(size: 40))
                
            }
            .frame(width: 100, height: 100)
            
        
            Text(countdown.gestureType.displayName)
                .font(.title3.bold())
                .foregroundColor(.white)
            
            Text(String(format: "%.1f", countdown.secondsRemaining) + "秒後にアクションを実行します")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.black.opacity(0.7))
        )
    }
}

// MARK: - Permission Denied View

enum PermissionType {
    case camera
    case accessibility
    
    var title: String {
        switch self {
        case .camera:
            return "カメラの権限が必要です"
        case .accessibility:
            return "アクセシビリティの権限が必要です"
        }
    }
    
    var description: String {
        switch self {
        case .camera:
            return "ジェスチャー検出にはカメラへのアクセスが必要です。システム設定で許可してください。"
        case .accessibility:
            return "ショートカットキーの送信にはアクセシビリティへのアクセスが必要です。システム設定で許可してください。"
        }
    }
    
    var iconName: String {
        switch self {
        case .camera:
            return "video.slash.fill"
        case .accessibility:
            return "hand.raised.slash.fill"
        }
    }
}

struct PermissionDeniedView: View {
    let permissionType: PermissionType
    let onOpenSettings: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: permissionType.iconName)
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            // Title
            Text(permissionType.title)
                .font(.title2.bold())
                .foregroundColor(.primary)
            
            // Description
            Text(permissionType.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            // Buttons
            VStack(spacing: 12) {
                Button(action: onOpenSettings) {
                    HStack {
                        Image(systemName: "gear")
                        Text("システム設定を開く")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue)
                    )
                }
                .buttonStyle(.plain)
                
                Button(action: onClose) {
                    Text("閉じる")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 40)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    CountdownOverlayView(countdown: GestureCountdown(gestureType: .heart, secondsRemaining: 0.75), totalSeconds: 1.5)
}
