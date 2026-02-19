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
    
    private let sendCommitDataUseCase: SendCommitDataUseCase
    
    private let gestureUseCase: GestureDetectionUseCase
    private var cancellables = Set<AnyCancellable>()
    
    enum AppStatus: Equatable {
        case waiting
        case detecting
        case success
        case unauthorized
        case error(Error)
        
        static func == (lhs: AppStatus, rhs: AppStatus) -> Bool {
            switch (lhs, rhs) {
            case (.waiting, .waiting),
                 (.detecting, .detecting),
                 (.success, .success),
                 (.unauthorized, .unauthorized):
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
        gestureUseCase: GestureDetectionUseCase,
        sendCommitDataUseCase: SendCommitDataUseCase
    ) {
        self.cameraUseCase = cameraUseCase
        self.gestureUseCase = gestureUseCase
        self.sendCommitDataUseCase = sendCommitDataUseCase
        print("GestureCameraViewModel initialized")
        checkPermission()
        setupBindings()
        setupCoordinatorBinding()
    }
    
    private func setupCoordinatorBinding() {
        // AppCoordinatorの状態を監視してappStateを更新
        DependencyContainer.shared.appCoordinator.$currentState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] coordinatorState in
                self?.updateAppStatus(from: coordinatorState)
            }
            .store(in: &cancellables)
    }
    
    private func updateAppStatus(from coordinatorState: AppState) {
        switch coordinatorState {
        case .detectingHeart:
            appState = .detecting
        case .commitSuccess:
            appState = .success
        case .commitError(let error):
            appState = .error(error)
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
        case .success, .error:
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
