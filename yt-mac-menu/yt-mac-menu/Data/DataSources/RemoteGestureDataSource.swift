import Foundation
import Combine

class RemoteGestureDataSource {
    private let webSocketClient: WebSocketClientProtocol
    private let eventSubject = PassthroughSubject<GestureEvent, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    var eventPublisher: AnyPublisher<GestureEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }
    
    init(webSocketClient: WebSocketClientProtocol) {
        self.webSocketClient = webSocketClient
        setupBindings()
    }
    
    private func setupBindings() {
        webSocketClient.messagePublisher
            .sink { [weak self] message in
                self?.handleMessage(message)
            }
            .store(in: &cancellables)
        
        webSocketClient.connectionStatusPublisher
            .sink { [weak self] isConnected in
                if isConnected {
                    self?.eventSubject.send(.connected)
                } else {
                    self?.eventSubject.send(.disconnected)
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleMessage(_ jsonString: String) {
        guard let data = jsonString.data(using: .utf8) else { return }
        
        struct ServerEvent: Decodable {
            let event: String
            let count: Int?
        }
        
        if let decoded = try? JSONDecoder().decode(ServerEvent.self, from: data) {
            switch decoded.event {
            case "heart":
                print("✅ ハート受信")
                eventSubject.send(.heartDetected)
            case "hand_count":
                print("✅ 手の数受信: \(decoded.count ?? -1)")
                if let count = decoded.count {
                    eventSubject.send(.handCount(count))
                }
            case "snap":
                print("✅ スナップ受信")
                eventSubject.send(.snapDetected)
            default:
                break
            }
        }
    }
}
