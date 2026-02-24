import Foundation
import Combine

class WebSocketClient: WebSocketClientProtocol {
    @Published private(set) var isConnected: Bool = false
    
    private let messageSubject = PassthroughSubject<String, Never>()
    private let connectionStatusSubject = PassthroughSubject<Bool, Never>()
    
    var messagePublisher: AnyPublisher<String, Never> {
        messageSubject.eraseToAnyPublisher()
    }
    
    var connectionStatusPublisher: AnyPublisher<Bool, Never> {
        connectionStatusSubject.eraseToAnyPublisher()
    }
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var retryAttempt = 0
    private let url: URL
    private let session = URLSession(configuration: .default)
    private let maxRetryInterval: TimeInterval = 30.0
    
    init(url: URL) {
        self.url = url
    }
    
    func connect() {
        if isConnected { return }
        
        webSocketTask?.cancel()
        webSocketTask = nil
        
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        print("WebSocketClient: 接続開始...")
        
        establishConnection()
    }
    
    func disconnect() {
        print("WebSocketClient: 手動切断")
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        
        DispatchQueue.main.async {
            self.isConnected = false
            self.connectionStatusSubject.send(false)
        }
    }
    
    func send(message: String) {
        let wsMessage = URLSessionWebSocketTask.Message.string(message)
        
        webSocketTask?.send(wsMessage) { [weak self] error in
            if let error = error {
                self?.handleConnectionError(error)
            }
        }
    }
    
    private func establishConnection() {
        webSocketTask?.sendPing { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                self.handleConnectionError(error)
            } else {
                DispatchQueue.main.async {
                    self.isConnected = true
                    self.retryAttempt = 0
                    self.connectionStatusSubject.send(true)
                    print("WebSocketClient: 接続確立(isConnected = true)")
                }
                self.receiveMessage()
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
        case .string(let str):
            text = str
        case .data(let data):
            text = String(data: data, encoding: .utf8)
        @unknown default:
            break
        }
        
        if let text = text {
            messageSubject.send(text)
        }
    }
    
    private func handleConnectionError(_ error: Error?) {
        print("WebSocketClient エラー発生: \(String(describing: error))")
        
        webSocketTask?.cancel(with: .abnormalClosure, reason: nil)
        webSocketTask = nil
        
        DispatchQueue.main.async {
            self.isConnected = false
            self.connectionStatusSubject.send(false)
            self.scheduleReconnection()
        }
    }
    
    private func scheduleReconnection() {
        let delay = min(pow(2.0, Double(retryAttempt)), maxRetryInterval)
        print("再接続を試みます... (\(Int(delay))秒後 / 試行回数: \(retryAttempt + 1))")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            self.retryAttempt += 1
            self.connect()
        }
    }
}
