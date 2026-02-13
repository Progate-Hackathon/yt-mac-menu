import AVFoundation
import Combine

class AppViewModel: ObservableObject {
    private let service = GestureService.shared
    
    @Published var isCameraVisible: Bool = false
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
        service.connect()
    }
    
    private func setupBindings() {
        service.eventSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self = self else { return }
                
                switch event {
                case .connected:
                    self.service.sendCommand(.enableSnap)
                case .disconnected:
                    self.isCameraVisible = false
                case .snapDetected:
                    self.service.sendCommand(.disableSnap)
                    self.service.sendCommand(.enableHeart)
                    self.isCameraVisible = true
                case .heartDetected:
                    self.service.sendCommand(.disableHeart)
                    scheduleAutoReset {
                        self.service.sendCommand(.enableSnap)
                    }
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }
    private func scheduleAutoReset(onComplete: (() -> Void)? = nil) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.isCameraVisible = false
            onComplete?()
        }
    }
}
