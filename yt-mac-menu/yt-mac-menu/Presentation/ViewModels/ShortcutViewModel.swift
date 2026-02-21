import SwiftUI
import Combine

@MainActor
final class ShortcutViewModel: ObservableObject {

    // MARK: - Properties

    @Published var currentHotkey: Hotkey
    @Published var actionType: ActionType
    @Published var isRecording: Bool = false
    @Published var showSuccess: Bool = false
    @Published var tempModifiers: NSEvent.ModifierFlags = []
    @Published var tempKeyDisplay: String = ""
    
    var onRecordingComplete: (() -> Void)?

    private let inputMonitor = InputMonitorService()

    // MARK: - Lifecycle

    init() {
        self.currentHotkey = UserDefaultsManager.shared.get(key: .hotkeyConfig, type: Hotkey.self)
            ?? Hotkey(modifiers: .option, keyCode: 49, keyDisplay: "Space")
        self.actionType = UserDefaultsManager.shared.get(key: .actionType, type: ActionType.self) ?? .commit

        setupRecorderCallbacks()
    }

    deinit {
        print("ShortcutViewModel: deinit呼び出し - クリーンアップ開始")
        // MainActorコンテキストで同期的にクリーンアップ
        // deinitはnonisolatedなので、DispatchQueueを使う
        let monitor = inputMonitor
        DispatchQueue.main.async {
            monitor.cleanup()
        }
    }

    // MARK: - Setup

    private func setupRecorderCallbacks() {
        inputMonitor.onUpdate = { [weak self] modifiers, keyDisplay in
            self?.tempModifiers = modifiers
            self?.tempKeyDisplay = keyDisplay
        }

        inputMonitor.onComplete = { [weak self] modifiers, keyCode, display in
            self?.completeRecording(modifiers: modifiers, keyCode: keyCode, display: display)
        }
    }

    // MARK: - Recorder

    func startRecording() {
        print("ShortcutViewModel: startRecording呼び出し")
        isRecording = true
        showSuccess = false
        tempModifiers = []
        tempKeyDisplay = ""
        
        inputMonitor.startMonitoring()
    }

    func stopRecording() {
        print("ShortcutViewModel: stopRecording呼び出し")
        inputMonitor.stopMonitorOnly()  // コールバックは保持したまま停止
        isRecording = false
    }

    private func completeRecording(modifiers: NSEvent.ModifierFlags, keyCode: UInt16, display: String) {
        print("ShortcutViewModel: ショートカット記録完了 - \(display), keyCode: \(keyCode), modifiers: \(modifiers)")
        let newHotkey = Hotkey(modifiers: modifiers, keyCode: keyCode, keyDisplay: display)
        print("ShortcutViewModel: 保存前のホットキー: \(currentHotkey.displayString)")
        saveHotkey(newHotkey)
        currentHotkey = newHotkey
        print("ShortcutViewModel: 保存後のホットキー: \(currentHotkey.displayString)")
        showSuccess = true

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            stopRecording()
            showSuccess = false
            tempKeyDisplay = ""
            tempModifiers = []
            onRecordingComplete?()  // ポップオーバーを閉じる通知
        }
    }

    // MARK: - Actions

    func saveHotkey(_ hotkey: Hotkey) {
        print("ShortcutViewModel: UserDefaultsに保存中 - \(hotkey.displayString)")
        UserDefaultsManager.shared.save(key: .hotkeyConfig, value: hotkey)
        
        // 保存確認
        if let saved = UserDefaultsManager.shared.get(key: .hotkeyConfig, type: Hotkey.self) {
            print("ShortcutViewModel: 保存確認OK - \(saved.displayString)")
        } else {
            print("ShortcutViewModel: ⚠️ 保存確認NG - UserDefaultsから読み取れません")
        }
    }

    func saveActionType(_ type: ActionType) {
        UserDefaultsManager.shared.save(key: .actionType, value: type)
        actionType = type
    }

    func runTestShortcut() {
        KeySender.activatePreviousAppAndSimulateShortcut(
            keyCode: currentHotkey.keyCode,
            modifiers: currentHotkey.modifiers
        )
    }
}
