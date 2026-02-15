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
    
    private let commitDataModelUseCase: CommitDataModelUseCase
    
    private let gestureUseCase: GestureDetectionUseCase
    private var cancellables = Set<AnyCancellable>()
    
    enum AppStatus: String {
        case waiting
        case detecting
        case success
        case unauthorized
    }
    
    init(
        cameraUseCase: CameraManagementUseCase,
        gestureUseCase: GestureDetectionUseCase,
        commitDataModelUseCase: CommitDataModelUseCase
    ) {
        self.cameraUseCase = cameraUseCase
        self.gestureUseCase = gestureUseCase
        self.commitDataModelUseCase = commitDataModelUseCase
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
                        self.handleHeartDetected()
                    case .handCount(let detectedHandCount):
                        self.detectedHandCount = detectedHandCount
                    default:
                        break
                }
            }
            .store(in: &cancellables)
    }
    
    
    // AWS側にCommitDataを送信しappStateをsuccessに更新する
    private func handleHeartDetected() {
        Task {
            do {
                try await commitDataModelUseCase.sendCommitData()
                self.appState = .success
            } catch {
                // TODO: AWS側への送信ロジックが完成したら　エラー処理を実装
                print("GestureViewModel/\(#function) エラー発生 \(error.localizedDescription)")
            }
        }
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
