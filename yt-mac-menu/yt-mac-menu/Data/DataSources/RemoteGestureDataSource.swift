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
            let event: String?
            let type: String?
            let count: Int?
            let status: String?
            let phase: String?
            let collected: Int?
            let target: Int?
        }
        
        guard let decoded = try? JSONDecoder().decode(ServerEvent.self, from: data) else {
            print("⚠️ Failed to decode event: \(jsonString)")
            return
        }
        
        // Handle status events first (they don't have 'event' field)
        if let status = decoded.status {
            print("📋 Server status: \(status)")
            return
        }
        
        // Ensure event field exists for other event types
        guard let eventTypeString = decoded.event else {
            print("⚠️ Missing event field: \(jsonString)")
            return
        }
        
        // Dynamic event type parsing
        guard let eventType = EventType(rawValue: eventTypeString) else {
            print("⚠️ Unknown event type: \(eventTypeString)")
            return
        }
        
        print("📨 Received: event=\(eventTypeString), type=\(decoded.type ?? "nil"), count=\(decoded.count ?? -1)")
        
        switch eventType {
        case .audio:
            guard let typeString = decoded.type else {
                print("⚠️ audio event missing type field")
                return
            }
            
            if let audioType = AudioType(rawValue: typeString) {
                print("✅ オーディオ受信: \(typeString)")
                eventSubject.send(.audioDetected(audioType))
            } else {
                print("⚠️ Unknown audio type: \(typeString)")
            }
            
        case .gesture:
            guard let typeString = decoded.type else {
                print("⚠️ gesture event missing type field")
                return
            }
            
            if let gestureType = GestureType(rawValue: typeString) {
                print("✅ ジェスチャー受信: \(typeString)")
                eventSubject.send(.gestureDetected(gestureType))
            } else {
                print("⚠️ Unknown gesture type: \(typeString)")
            }
            
        case .gestureLost:
            guard let typeString = decoded.type else {
                print("⚠️ gesture_lost event missing type field")
                return
            }
            
            if let gestureType = GestureType(rawValue: typeString) {
                print("🚫 Gesture lost: \(typeString)")
                eventSubject.send(.gestureLost(gestureType))
            } else {
                print("⚠️ gesture_lost with invalid type: \(typeString)")
            }
            
        case .handCount:
            print("✅ 手の数受信: \(decoded.count ?? -1)")
            if let count = decoded.count {
                eventSubject.send(.handCount(count))
            }
            
        case .snapCalibration:
            guard let phase = decoded.phase else {
                print("⚠️ snap_calibration event missing phase field")
                return
            }
            if phase == "completed" {
                print("✅ スナップキャリブレーション完了")
                eventSubject.send(.snapCalibrationCompleted)
            } else if phase == "progress" {
                let collected = decoded.collected ?? 0
                let target = decoded.target ?? 15
                print("📊 スナップキャリブレーション進捗: \(collected)/\(target)")
                eventSubject.send(.snapCalibrationProgress(collected: collected, target: target))
            }
        }
    }
}
