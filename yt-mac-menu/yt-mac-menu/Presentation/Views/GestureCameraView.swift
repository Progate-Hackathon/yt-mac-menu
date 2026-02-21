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
                            CountdownOverlayView(countdown: countdown, totalSeconds: 3)
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
    let totalSeconds: Int   // ← 追加
    
    private var progress: Double {
        Double(countdown.secondsRemaining) / Double(totalSeconds)
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
            
            Text("\(countdown.secondsRemaining)秒後にアクションを実行します")
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

#Preview {
    CountdownOverlayView(countdown: GestureCountdown(gestureType: .heart, secondsRemaining: 1), totalSeconds: 4)
}
