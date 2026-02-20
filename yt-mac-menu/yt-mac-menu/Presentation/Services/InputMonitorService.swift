import AppKit

/// キーボード入力を監視し、結果を通知するクラス
@MainActor
final class InputMonitorService {
    
    // イベント通知用
    var onUpdate: ((_ modifiers: NSEvent.ModifierFlags, _ keyDisplay: String) -> Void)?
    var onComplete: ((_ modifiers: NSEvent.ModifierFlags, _ keyCode: UInt16, _ keyDisplay: String) -> Void)?
    
    private var localMonitor: Any?
    
    func startMonitoring() {
        print("InputMonitorService: モニタリング開始")
        stopMonitoring() // 重複防止
        
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            print("InputMonitorService: イベント受信 - type: \(event.type.rawValue), keyCode: \(event.keyCode)")
            // Escapeキー(keyCode 53)は通してキャンセルできるようにする
            if event.type == .keyDown && event.keyCode == 53 {
                print("InputMonitorService: Escapeキー検出 - キャンセル")
                Task { @MainActor in
                    self?.stopMonitoring()
                }
                return event
            }
            Task { @MainActor in
                self?.handleEvent(event)
            }
            return nil // 監視中はイベントを他に流さない（入力無効化）
        }
        
        if localMonitor != nil {
            print("InputMonitorService: ✅ モニター登録成功")
        } else {
            print("InputMonitorService: ⚠️ モニター登録失敗")
        }
    }
    
    func stopMonitoring() {
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
            print("InputMonitorService: モニタリング停止")
        }
    }
    
    private func handleEvent(_ event: NSEvent) {
        let modifiers = event.modifierFlags.intersection([.command, .option, .control, .shift])
        
        if event.type == .flagsChanged {
            onUpdate?(modifiers, "")
            return
        }
        
        if event.type == .keyDown {
            guard let chars = event.charactersIgnoringModifiers, !chars.isEmpty else { return }
            
            let keyCode = event.keyCode
            let display: String = (keyCode == 49) ? "Space" : chars.uppercased()
            
            print("InputMonitorService: キー検出 - \(display), keyCode: \(keyCode), modifiers: \(modifiers)")
            
            if !modifiers.isEmpty {
                print("InputMonitorService: ✅ 完全なショートカット検出 - onCompleteコールバック呼び出し")
                onComplete?(modifiers, keyCode, display)
                stopMonitoring()
            } else {
                print("InputMonitorService: ⚠️ モディファイアなし - onUpdateコールバック呼び出し")
                onUpdate?(modifiers, display)
            }
        }
    }
}
