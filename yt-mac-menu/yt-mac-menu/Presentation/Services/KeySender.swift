import Foundation
import CoreGraphics
import AppKit

/// キーボードショートカットを送信するユーティリティクラス
final class KeySender {
    
    // MARK: - Properties
    
    /// ショートカット実行時に使用する直前のアプリ
    private static var previousActiveApp: NSRunningApplication?
    
    /// 最後にアクティブだった非自アプリ
    private static var lastNonSelfActiveApp: NSRunningApplication?
    
    /// ワークスペース通知の監視トークン
    private static var observer: NSObjectProtocol?
    
    // MARK: - Observer
    
    /// アクティブアプリの監視を開始
    static func startObservingActiveApp() {
        guard observer == nil else { return }
        
        // 初期値を設定
        if let currentApp = NSWorkspace.shared.frontmostApplication,
           !isSelfApp(currentApp) {
            lastNonSelfActiveApp = currentApp
        }
        
        // アクティブアプリ変更を監視
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
                return
            }
            
            if isSelfApp(app) {
                // 自アプリがアクティブになった → 直前のアプリを保存
                previousActiveApp = lastNonSelfActiveApp
            } else {
                // 他のアプリがアクティブになった → 記録
                lastNonSelfActiveApp = app
            }
        }
    }
    
    /// 監視を停止
    static func stopObservingActiveApp() {
        if let observer = observer {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            self.observer = nil
        }
    }
    
    // MARK: - Shortcut Execution
    
    /// 直前のアプリをアクティブにしてショートカットを実行
    static func activatePreviousAppAndSimulateShortcut(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
        guard let app = previousActiveApp else {
            NSLog("KeySender: 直前のアクティブアプリが見つかりません。ショートカットは実行されません。")
            return
        }
        
        // アプリをアクティブにして、完了後にショートカットを実行
        app.activate()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            sendKeyEvent(keyCode: keyCode, modifiers: modifiers, to: app)
        }
    }
    
    /// 指定したアプリにキーイベントを送信
    private static func sendKeyEvent(keyCode: UInt16, modifiers: NSEvent.ModifierFlags, to app: NSRunningApplication) {
        let pid = app.processIdentifier
        let source = CGEventSource(stateID: .hidSystemState)
        
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) else {
            return
        }
        
        let cgModifiers = convertToCGEventFlags(modifiers)
        keyDown.flags = cgModifiers
        keyUp.flags = cgModifiers
        
        keyDown.postToPid(pid)
        keyUp.postToPid(pid)
    }
    
    // MARK: - Helpers
    
    private static func isSelfApp(_ app: NSRunningApplication) -> Bool {
        app.bundleIdentifier == Bundle.main.bundleIdentifier
    }
    
    private static func convertToCGEventFlags(_ modifiers: NSEvent.ModifierFlags) -> CGEventFlags {
        var flags: CGEventFlags = []
        if modifiers.contains(.command) { flags.insert(.maskCommand) }
        if modifiers.contains(.option) { flags.insert(.maskAlternate) }
        if modifiers.contains(.control) { flags.insert(.maskControl) }
        if modifiers.contains(.shift) { flags.insert(.maskShift) }
        return flags
    }
    
    /// 修飾キーを表示用文字列に変換
    static func formatModifiers(_ modifiers: NSEvent.ModifierFlags) -> String {
        var result = ""
        if modifiers.contains(.control) { result += "⌃ " }
        if modifiers.contains(.option) { result += "⌥ " }
        if modifiers.contains(.shift) { result += "⇧ " }
        if modifiers.contains(.command) { result += "⌘ " }
        return result
    }
}
