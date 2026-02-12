import Foundation
import Combine
import SwiftUI

class GestureDetectionViewModel: ObservableObject {
    @Published var appState: AppStatus = .waiting {
        didSet { handleStateChange(appState) }
    }
    private var monitorWindow: NSWindow?
    private var webSocketTask: URLSessionWebSocketTask?

    enum AppStatus: String {
        case waiting
        case detecting
        case success
    }

    init() {
        // 必要ならここで接続開始
        // connectWebSocket()
        // テスト用に初期状態をdetectingに設定
        self.appState = .detecting
    }
    
    private func handleStateChange(_ state: AppStatus) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            switch state {
            case .detecting:
                break
            case .success:
                self.scheduleAutoReset()
            case .waiting:
                break
            }
        }
    }
    
    private func scheduleAutoReset() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.appState = .waiting
        }
    }
    
    private func connectWebSocket() {
        guard let url = URL(string: "ws://localhost:8765") else { return }
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()
        receiveMessage()
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                if case .string(let text) = message {
                    DispatchQueue.main.async {
                        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        if let newState = AppStatus(rawValue: cleanText) {
                            self.appState = newState
                        } else {
                            print("Warning: Unknown status received: '\(cleanText)'")
                        }
                    }
                }
                self.receiveMessage()
                
            case .failure(let error):
                print("WebSocket Error: \(error)")
                // 切断時は2秒後に再接続
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.connectWebSocket()
                }
            }
        }
    }
}
