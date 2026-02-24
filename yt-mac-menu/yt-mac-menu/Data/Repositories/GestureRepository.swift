import Foundation
import Combine

class GestureRepository: GestureRepositoryProtocol {
    private let webSocketClient: WebSocketClientProtocol
    private let remoteDataSource: RemoteGestureDataSource
    
    var eventPublisher: AnyPublisher<GestureEvent, Never> {
        remoteDataSource.eventPublisher
    }
    
    var isConnected: Bool {
        webSocketClient.isConnected
    }
    
    init(webSocketClient: WebSocketClientProtocol, remoteDataSource: RemoteGestureDataSource) {
        self.webSocketClient = webSocketClient
        self.remoteDataSource = remoteDataSource
    }
    
    func connect() {
        webSocketClient.connect()
    }
    
    func disconnect() {
        webSocketClient.disconnect()
    }
    
    func sendCommand(_ command: GestureCommand) {
        let jsonString = "{\"command\": \"\(command.rawValue)\"}"
        webSocketClient.send(message: jsonString)
    }
}
