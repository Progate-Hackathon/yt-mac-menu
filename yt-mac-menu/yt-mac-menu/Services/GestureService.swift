import Foundation
import Combine

enum GestureEvent {
    case heartDetected
    case handCount(Int)
    case snapDetected
    case connected
    case disconnected
}


class GestureService: ObservableObject {
    
    static let shared = GestureService()
    
    @Published var isConnected: Bool = false
    let eventSubject = PassthroughSubject<GestureEvent, Never>()
    
    private var webSocketTask: URLSessionWebSocketTask?
    private let url = URL(string: "ws://localhost:8765")!
    
    private init() {}
    
    func connect() {
        if isConnected { return }
        
        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        print("GestureService: 接続開始...")
        
        receiveMessage()
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        DispatchQueue.main.async { self.isConnected = false }
        eventSubject.send(.disconnected)
    }
    
    func sendCommand(_ command: String) {
        let jsonString = "{\"command\": \"\(command)\"}"
        let message = URLSessionWebSocketTask.Message.string(jsonString)
        
        webSocketTask?.send(message) { error in
            if let error = error {
                print("GestureService 送信エラー: \(error)")
            }
        }
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                if !self.isConnected {
                    DispatchQueue.main.async {
                        self.isConnected = true
                        print("GestureService: 接続確立(isConnected = true)")
                    }
                    self.eventSubject.send(.connected)
                }
                
                self.handleMessage(message)
                self.receiveMessage()
                
            case .failure(let error):
                print("GestureService 受信エラー: \(error)")
                // 👇 状態更新
                DispatchQueue.main.async { self.isConnected = false }
                self.eventSubject.send(.disconnected)
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        var text: String?
        
        switch message {
        case .string(let str): text = str
        case .data(let data): text = String(data: data, encoding: .utf8)
        @unknown default: break
        }
        
        guard let jsonString = text,
              let data = jsonString.data(using: .utf8) else { return }
        
        struct ServerEvent: Decodable {
            let event: String
            let count: Int?
        }
        
        if let decoded = try? JSONDecoder().decode(ServerEvent.self, from: data) {
            switch decoded.event {
            case "heart":
                print("✅ Swift側でハート受信！")
                eventSubject.send(.heartDetected)
            case "hand_count":
                print("✅ Swift側で手の指の本数\(decoded.count ?? 0)受信！")
                if let count = decoded.count {
                    eventSubject.send(.handCount(count))
                }
            case "snap":
                print("✅ Swift側でスナップ受信！")
                eventSubject.send(.snapDetected)
            default:
                break
            }
        }
    }
}
