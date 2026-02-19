@preconcurrency import Foundation
import CoreGraphics
import AppKit

/// キーボードショートカットを送信するユーティリティクラス
@MainActor
final class KeySender {
    
    // MARK: - Properties
    
    /// ショートカット実行時に使用する直前のアプリ
    private static var previousActiveApp: NSRunningApplication?
    
    /// 最後にアクティブだった非自アプリ
    private static var lastNonSelfActiveApp: NSRunningApplication?
    
    /// ワークスペース通知の監視トークン
    private static var observer: NSObjectProtocol?

    /// ショートカット送信用の一時オブザーバー
    private static var shortcutActivationObserver: NSObjectProtocol?
    
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
            MainActor.assumeIsolated {
                guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
                    return
                }

                if isSelfApp(app) {
                    previousActiveApp = lastNonSelfActiveApp
                } else {
                    lastNonSelfActiveApp = app
                }
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

        var didFire = false

        // 対象アプリがアクティブになった通知を待ち受ける
        shortcutActivationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { notification in
            MainActor.assumeIsolated {
                guard
                    !didFire,
                    let activatedApp = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                    activatedApp.processIdentifier == app.processIdentifier
                else { return }

                didFire = true
                if let obs = shortcutActivationObserver {
                    NSWorkspace.shared.notificationCenter.removeObserver(obs)
                    shortcutActivationObserver = nil
                }
                sendKeyEvent(keyCode: keyCode, modifiers: modifiers, to: app)
            }
        }

        app.activate()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            MainActor.assumeIsolated {
                guard !didFire else { return }
                didFire = true
                if let obs = shortcutActivationObserver {
                    NSWorkspace.shared.notificationCenter.removeObserver(obs)
                    shortcutActivationObserver = nil
                }
                sendKeyEvent(keyCode: keyCode, modifiers: modifiers, to: app)
            }
        }
    }
    
    /// 指定したアプリにキーイベントを送信
    private static func sendKeyEvent(keyCode: UInt16, modifiers: NSEvent.ModifierFlags, to app: NSRunningApplication) {
        guard AXIsProcessTrusted() else {
            NSLog("KeySender: アクセシビリティ権限がありません。")
            let alert = NSAlert()
            alert.messageText = "アクセシビリティ権限が必要です"
            alert.informativeText = "ショートカットを実行するには、システム設定 > プライバシーとセキュリティ > アクセシビリティ でこのアプリを許可してください。"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "システム設定を開く")
            alert.addButton(withTitle: "キャンセル")
            if alert.runModal() == .alertFirstButtonReturn {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
            }
            return
        }

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
