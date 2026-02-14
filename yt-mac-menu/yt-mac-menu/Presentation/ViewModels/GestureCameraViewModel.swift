import AVFoundation
import SwiftUI
import Combine

class GestureCameraViewModel: ObservableObject {
    @Published var appState: AppStatus = .waiting {
        didSet { handleStateChange(appState) }
    }
    
    let cameraUseCase: CameraManagementUseCase
    
    var session: AVCaptureSession {
        cameraUseCase.session
    }
    
    private let gestureUseCase: GestureDetectionUseCase
    private var cancellables = Set<AnyCancellable>()
    
    enum AppStatus: String {
        case waiting
        case detecting
        case success
        case unauthorized
    }
    
    init(cameraUseCase: CameraManagementUseCase, gestureUseCase: GestureDetectionUseCase) {
        self.cameraUseCase = cameraUseCase
        self.gestureUseCase = gestureUseCase
        print("GestureCameraViewModel initialized")
        checkPermission()
        setupBindings()
    }
    
    private func setupBindings() {
        gestureUseCase.gestureEventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self = self else { return }
                switch event {
                case .heartDetected:
                    self.appState = .success
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
        case .success:
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
