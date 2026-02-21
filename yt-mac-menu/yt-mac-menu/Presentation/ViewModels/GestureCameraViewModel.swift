import AVFoundation
import SwiftUI
import Combine

// MARK: - View State Representation

struct ViewStateRepresentation {
    let title: String
    let subtitle: String
    let iconName: String
    let color: Color
}

// MARK: - ViewModel

class GestureCameraViewModel: ObservableObject {
    @Published var gestureCameraViewState: GestureCameraViewState = .waitingSnap {
        didSet { handleStateChange(gestureCameraViewState) }
    }

    @Published var detectedHandCount: Int = 0
    
    let cameraUseCase: CameraManagementUseCase
    
    var session: AVCaptureSession {
        cameraUseCase.session
    }
    
    private let gestureUseCase: GestureDetectionUseCase
    private var cancellables = Set<AnyCancellable>()
    
    enum GestureCameraViewState: Equatable {
        case waitingSnap
        case detectingGesture
        case committingData
        case gestureDetected(GestureType, countdown: Int)
        case executingAction
        case unauthorized
        case commitSuccess
        case shortcutSuccess
        case commandResult(ShellResult)
        case error(Error)
        
        static func == (lhs: GestureCameraViewState, rhs: GestureCameraViewState) -> Bool {
            switch (lhs, rhs) {
            case (.waitingSnap, .waitingSnap),
                 (.detectingGesture, .detectingGesture),
                 (.committingData, .committingData),
                 (.executingAction, .executingAction),
                 (.commitSuccess, .commitSuccess),
                 (.unauthorized, .unauthorized),
                 (.commandResult, .commandResult),
                 (.shortcutSuccess, .shortcutSuccess):
                return true
            case (.gestureDetected(let lhsGesture, let lhsCountdown), .gestureDetected(let rhsGesture, let rhsCountdown)):
                return lhsGesture == rhsGesture && lhsCountdown == rhsCountdown
            case (.error(let lhsError), .error(let rhsError)):
                return lhsError.localizedDescription == rhsError.localizedDescription
            default:
                return false
            }
        }
    }
    
    init(
        cameraUseCase: CameraManagementUseCase,
        gestureUseCase: GestureDetectionUseCase
    ) {
        self.cameraUseCase = cameraUseCase
        self.gestureUseCase = gestureUseCase
        print("GestureCameraViewModel initialized")
        checkPermission()
        setupBindings()
        setupCoordinatorBinding()
    }
    
    private func setupCoordinatorBinding() {
        let coordinator = DependencyContainer.shared.appCoordinator

        // AppCoordinatorの状態を監視してappStateを更新
        coordinator.$currentState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] coordinatorState in
                self?.updateAppStatus(from: coordinatorState)
            }
            .store(in: &cancellables)

        // コマンド結果を監視して結果表示状態に遷移
        coordinator.$commandResult
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] result in
                self?.gestureCameraViewState = .commandResult(result)
            }
            .store(in: &cancellables)
    }
    
    private func updateAppStatus(from coordinatorState: AppState) {
        // コマンド結果表示中は coordinatorState による上書きをしない
        if case .commandResult = gestureCameraViewState { return }

        switch coordinatorState {
            case .detectingGesture:
                gestureCameraViewState = .detectingGesture
            case .gestureDetected(let gestureType, let countdown):
                gestureCameraViewState = .gestureDetected(gestureType, countdown: countdown)
            case .executingAction:
                gestureCameraViewState = .executingAction
            case .commitSuccess:
                gestureCameraViewState = .commitSuccess
            case .commitError(let error):
                gestureCameraViewState = .error(error)
            case .shortcutSuccess:
                gestureCameraViewState = .shortcutSuccess
            case .committingData:
                gestureCameraViewState = .committingData
            case .idle, .listeningForSnap, .resetting, .snapDetected:
                break
        }
    }
    
    private func setupBindings() {
        gestureUseCase.gestureEventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self = self else { return }
                switch event {
                    case .handCount(let detectedHandCount):
                        self.detectedHandCount = detectedHandCount
                    default:
                        break
                }
            }
            .store(in: &cancellables)
    }
    

    private func handleStateChange(_ state: GestureCameraViewState) {
        switch state {
        case .detectingGesture:
            cameraUseCase.startCamera()
        case .commitSuccess, .shortcutSuccess, .error, .commandResult, .committingData, .gestureDetected, .executingAction:
            cameraUseCase.stopCamera()
        case .waitingSnap, .unauthorized:
            break
        }
    }
    
    private func checkPermission() {
        cameraUseCase.requestPermission { [weak self] granted in
            guard let self = self else { return }
            if granted {
                self.cameraUseCase.setupCamera()
                self.gestureCameraViewState = .detectingGesture
            } else {
                self.gestureCameraViewState = .unauthorized
            }
        }
    }
}

// MARK: - View State Representation Extension

extension GestureCameraViewModel.GestureCameraViewState {
    var feedbackRepresentation: ViewStateRepresentation? {
        switch self {
        case .gestureDetected(let gestureType, let countdown):
            return ViewStateRepresentation(
                title: "\(gestureType.emoji) \(gestureType.displayName)検出",
                subtitle: "\(countdown)秒後にアクションを実行します",
                iconName: "timer",
                color: .blue
            )
            
        case .executingAction:
            return ViewStateRepresentation(
                title: "アクション実行中...",
                subtitle: "お待ちください",
                iconName: "gearshape.2",
                color: .orange
            )
            
        case .committingData:
            return ViewStateRepresentation(
                title: "データ送信中",
                subtitle: "しばらくお待ちください...",
                iconName: "arrow.up.circle.fill",
                color: .orange
            )
            
        case .commitSuccess:
            return ViewStateRepresentation(
                title: "コミット完了！",
                subtitle: "3秒後に閉じます...",
                iconName: "checkmark.circle.fill",
                color: .green
            )
            
        case .shortcutSuccess:
            return ViewStateRepresentation(
                title: "ショートカット実行完了！",
                subtitle: "3秒後に閉じます...",
                iconName: "checkmark.circle.fill",
                color: .green
            )
            
        case .unauthorized:
            return ViewStateRepresentation(
                title: "カメラの権限が必要です",
                subtitle: "システム環境設定で許可してください",
                iconName: "video.slash",
                color: .red
            )
            
        // Custom UI states - return nil
        case .waitingSnap, .detectingGesture, .commandResult, .error:
            return nil
        }
    }
}
