import Foundation
import Combine

class GestureDetectionUseCase {
    private let gestureRepository: GestureRepositoryProtocol
    
    var gestureEventPublisher: AnyPublisher<GestureEvent, Never> {
        gestureRepository.eventPublisher
    }
    
    init(gestureRepository: GestureRepositoryProtocol) {
        self.gestureRepository = gestureRepository
    }
    
    func startListeningForSnap() {
        gestureRepository.sendCommand(.enableSnap)
    }
    
    func stopListeningForSnap() {
        gestureRepository.sendCommand(.disableSnap)
    }
    
    func startListeningForHeart() {
        gestureRepository.sendCommand(.enableHeart)
    }
    
    func stopListeningForHeart() {
        gestureRepository.sendCommand(.disableHeart)
    }
    
    func connect() {
        gestureRepository.connect()
    }
    
    func disconnect() {
        gestureRepository.disconnect()
    }
}
