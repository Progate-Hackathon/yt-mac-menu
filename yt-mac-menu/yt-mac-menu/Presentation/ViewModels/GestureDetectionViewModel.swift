import Foundation
import Combine
import SwiftUI

class GestureDetectionViewModel: ObservableObject {
    @Published var detectionState: DetectionStatus = .waiting
    
    private let gestureUseCase: GestureDetectionUseCase
    private var cancellables = Set<AnyCancellable>()
    
    enum DetectionStatus: String {
        case waiting
        case detecting
        case success
        case unauthorized
    }
    
    init(gestureUseCase: GestureDetectionUseCase) {
        self.gestureUseCase = gestureUseCase
        setupBindings()
    }
    
    private func setupBindings() {
        gestureUseCase.gestureEventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self = self else { return }
                switch event {
                case .snapDetected:
                    self.detectionState = .detecting
                case .heartDetected:
                    self.detectionState = .success
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }
}
