import Foundation
import Combine

protocol WebSocketClientProtocol {
    var isConnected: Bool { get }
    var messagePublisher: AnyPublisher<String, Never> { get }
    var connectionStatusPublisher: AnyPublisher<Bool, Never> { get }
    
    func connect()
    func disconnect()
    func send(message: String)
}
