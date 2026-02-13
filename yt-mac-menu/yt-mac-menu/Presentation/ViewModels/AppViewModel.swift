import Foundation
import Combine

class AppViewModel: ObservableObject {
    @Published var isCameraVisible: Bool = false
    
    private let coordinator: AppCoordinator
    private var cancellables = Set<AnyCancellable>()
    
    init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
        setupBindings()
        coordinator.start()
    }
    
    private func setupBindings() {
        coordinator.$isCameraVisible
            .receive(on: DispatchQueue.main)
            .assign(to: &$isCameraVisible)
    }
}
