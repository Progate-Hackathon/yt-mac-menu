import Foundation
import Combine
import SwiftUI

class GestureDetectionViewModel: ObservableObject {
    @Published var appState: AppStatus = .waiting
    private var cancellables = Set<AnyCancellable>()
    
    private let service = GestureService.shared
    
    enum AppStatus: String {
        case waiting
        case detecting
        case success
        case unauthorized
    }
    
    init() {
        // テスト用に初期状態をdetectingに設定
        self.appState = .detecting
        setupBindings()
    }
    
    private func setupBindings() {
        service.eventSubject
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
}
