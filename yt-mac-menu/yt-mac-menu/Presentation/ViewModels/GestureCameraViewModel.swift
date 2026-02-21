import AVFoundation
import SwiftUI
import Combine

class GestureCameraViewModel: ObservableObject {
    @Published var appState: AppStatus = .waiting {
        didSet { handleStateChange(appState) }
    }

    @Published var detectedHandCount: Int = 0
    
    let cameraUseCase: CameraManagementUseCase
    
    var session: AVCaptureSession {
        cameraUseCase.session
    }
    
    private let gestureUseCase: GestureDetectionUseCase
    private var cancellables = Set<AnyCancellable>()
    
    enum AppStatus: Equatable {
        case waiting
        case detecting
        case success
        case unauthorized
        case shortcutSuccess
        case commandResult(ShellResult)
        case error(Error)
        
        static func == (lhs: AppStatus, rhs: AppStatus) -> Bool {
            switch (lhs, rhs) {
            case (.waiting, .waiting),
                 (.detecting, .detecting),
                 (.success, .success),
                 (.unauthorized, .unauthorized),
                 (.shortcutSuccess, .shortcutSuccess),
                 (.commandResult, .commandResult):
                return true
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
                self?.appState = .commandResult(result)
            }
            .store(in: &cancellables)
    }
    
    private func updateAppStatus(from coordinatorState: AppState) {
        // コマンド結果表示中は coordinatorState による上書きをしない
        if case .commandResult = appState { return }

        switch coordinatorState {
        case .detectingHeart:
            appState = .detecting
        case .commitSuccess:
            appState = .success
        case .commitError(let error):
            appState = .error(error)
        case .shortcutSuccess:
            appState = .shortcutSuccess
        default:
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
    

    private func handleStateChange(_ state: AppStatus) {
        switch state {
        case .detecting:
            cameraUseCase.startCamera()
        case .success, .shortcutSuccess, .error, .commandResult:
            cameraUseCase.stopCamera()
        case .waiting, .unauthorized:
            break
        }
    }
    
    private func checkPermission() {
        cameraUseCase.requestPermission { [weak self] granted in
            guard let self = self else { return }
            if granted {
                self.cameraUseCase.setupCamera()
                self.appState = .detecting
            } else {
                self.appState = .unauthorized
            }
        }
    }
}
