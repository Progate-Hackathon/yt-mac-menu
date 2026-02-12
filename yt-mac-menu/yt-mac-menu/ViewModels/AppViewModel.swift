import AVFoundation
import Combine

class AppViewModel: ObservableObject {
    private let service = GestureService.shared
    
    @Published var isCameraVisible: Bool = false
    private var cancellables = Set<AnyCancellable>() // 購読を保持するゴミ箱のようなもの
    
    init() {
        setupBindings()
        service.connect()
        service.sendCommand("enable_snap")
    }
    
    private func setupBindings() {
        service.eventSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self = self else { return }
                
                switch event {
                case .connected:
                    self.service.sendCommand("enable_snap")
                case .snapDetected:
                    self.service.sendCommand("disable_snap")
                    self.service.sendCommand("enable_heart")
                    self.isCameraVisible = true
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }
}
