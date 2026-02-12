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
    let eventSubject = PassthroughSubject<GestureEvent, Never>()
    
    @Published var isConnected: Bool = false
    private var webSocketTask: URLSessionWebSocketTask?
    private var retryAttempt = 0
    
    private let url = URL(string: "ws://localhost:8765")
    private let session = URLSession(configuration: .default)
    private let maxRetryInterval: TimeInterval = 30.0
    
    private init() {}
    
    func connect() {
        if isConnected { return }
        
        webSocketTask?.cancel()
        webSocketTask = nil
        
        guard let url = url else { return }
        
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        print("GestureService: 接続開始...")
        
        sendPingToConfirmConnection()
    }
    
    func disconnect() {
        print("GestureService: 手動切断")
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        DispatchQueue.main.async { self.isConnected = false }
        eventSubject.send(.disconnected)
    }
    
    private func handleConnectionError(_ error: Error?) {
        print("GestureService エラー発生: \(String(describing: error))")
        
        webSocketTask?.cancel(with: .abnormalClosure, reason: nil)
        webSocketTask = nil
        
        DispatchQueue.main.async {
            self.isConnected = false
            self.eventSubject.send(.disconnected)
            self.attemptReconnect()
        }
    }
    
    private func sendPingToConfirmConnection() {
        webSocketTask?.sendPing { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                self.handleConnectionError(error)
            } else {
                DispatchQueue.main.async {
                    self.isConnected = true
                    self.retryAttempt = 0
                    print("GestureService: 接続確立(isConnected = true)")
                }
                self.eventSubject.send(.connected)
                self.receiveMessage()
            }
        }
    }
    
    func sendCommand(_ command: String) {
        let jsonString = "{\"command\": \"\(command)\"}"
        let message = URLSessionWebSocketTask.Message.string(jsonString)
        
        webSocketTask?.send(message) { error in
            if let error = error {
                self.handleConnectionError(error)
            }
        }
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                self.handleMessage(message)
                self.receiveMessage()
                
            case .failure(let error):
                self.handleConnectionError(error)
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
                print("✅ Swift側でハート受信")
                eventSubject.send(.heartDetected)
            case "hand_count":
                print("✅ Swift側で手の数受信: \(decoded.count ?? -1)")
                if let count = decoded.count {
                    eventSubject.send(.handCount(count))
                }
            case "snap":
                print("✅ Swift側でスナップ受信")
                eventSubject.send(.snapDetected)
            default:
                break
            }
        }
    }
    
    private func attemptReconnect() {
        let delay = min(pow(2.0, Double(retryAttempt)), maxRetryInterval)
        print("再接続を試みます... (\(Int(delay))秒後 / 試行回数: \(retryAttempt + 1))")

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            self.retryAttempt += 1
            self.connect()
        }
    }
}
