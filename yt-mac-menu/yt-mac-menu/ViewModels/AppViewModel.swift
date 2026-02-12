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
                    self.service.sendCommand("enable_snap")
                case .disconnected:
                    self.isCameraVisible = false
                case .snapDetected:
                    self.service.sendCommand("disable_snap")
                    self.service.sendCommand("enable_heart")
                    self.isCameraVisible = true
                case .heartDetected:
                    self.isCameraVisible = false
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }
}
