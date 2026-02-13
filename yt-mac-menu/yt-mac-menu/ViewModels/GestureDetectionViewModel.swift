import Foundation
import Combine
import SwiftUI

class GestureDetectionViewModel: ObservableObject {
    @Published var detectionState: DetectionStatus = .waiting
    private var cancellables = Set<AnyCancellable>()
    
    private let service = GestureService.shared
    
    enum DetectionStatus: String {
        case waiting
        case detecting
        case success
        case unauthorized
    }
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        service.eventSubject
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
