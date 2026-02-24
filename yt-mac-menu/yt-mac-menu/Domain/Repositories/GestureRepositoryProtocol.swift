import Foundation
import Combine

protocol GestureRepositoryProtocol {
    var eventPublisher: AnyPublisher<GestureEvent, Never> { get }
    var isConnected: Bool { get }
    
    func connect()
    func disconnect()
    func sendCommand(_ command: GestureCommand)
}
