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

    // snap検知トリガー用
    @Published var snapTriggerHotkey: Hotkey?
    @Published var snapTriggerPreviewHotkey: Hotkey
    @Published var isRecordingSnapTrigger: Bool = false
    @Published var showSnapTriggerSuccess: Bool = false
    @Published var showSnapTriggerError: String? = nil
    @Published var tempSnapModifiers: NSEvent.ModifierFlags = []
    @Published var tempSnapKeyDisplay: String = ""
    var onRecordingComplete: (() -> Void)?
    var onSnapRecordingComplete: (() -> Void)?

    private let inputMonitor = InputMonitorService()
    private let snapTriggerMonitor = InputMonitorService()

    // MARK: - Lifecycle

    init() {
        self.currentHotkey = UserDefaultsManager.shared.get(key: .hotkeyConfig, type: Hotkey.self)
            ?? Hotkey(modifiers: .option, keyCode: 49, keyDisplay: "Space")
        self.actionType = UserDefaultsManager.shared.get(key: .actionType, type: ActionType.self) ?? .commit
        let savedSnapTrigger = UserDefaultsManager.shared.get(key: .snapTriggerHotkey, type: Hotkey.self)
        self.snapTriggerHotkey = savedSnapTrigger
        self.snapTriggerPreviewHotkey = savedSnapTrigger
            ?? Hotkey(modifiers: [], keyCode: 0, keyDisplay: "")

        setupRecorderCallbacks()
        setupSnapTriggerCallbacks()
    }

    deinit {
        print("ShortcutViewModel: deinit呼び出し - クリーンアップ開始")
        let monitor = inputMonitor
        let snapMonitor = snapTriggerMonitor
        DispatchQueue.main.async {
            monitor.cleanup()
            snapMonitor.cleanup()
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

    private func setupSnapTriggerCallbacks() {
        snapTriggerMonitor.onUpdate = { [weak self] modifiers, keyDisplay in
            self?.tempSnapModifiers = modifiers
            self?.tempSnapKeyDisplay = keyDisplay
        }
        snapTriggerMonitor.onComplete = { [weak self] modifiers, keyCode, display in
            self?.completeSnapTriggerRecording(modifiers: modifiers, keyCode: keyCode, display: display)
        }
    }

    // MARK: - Recorder

    func startRecording() {
        print("ShortcutViewModel: startRecording呼び出し")
        // 排他制御：snap記録中なら止める
        if isRecordingSnapTrigger { stopRecordingSnapTrigger() }
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

    // MARK: - Snap Trigger Recorder

    func startRecordingSnapTrigger() {
        print("ShortcutViewModel: startRecordingSnapTrigger呼び出し")
        // 排他制御：ハートショートカット記録中なら止める
        if isRecording { stopRecording() }
        isRecordingSnapTrigger = true
        showSnapTriggerSuccess = false
        tempSnapModifiers = []
        tempSnapKeyDisplay = ""
        snapTriggerMonitor.startMonitoring()
    }

    func stopRecordingSnapTrigger() {
        print("ShortcutViewModel: stopRecordingSnapTrigger呼び出し")
        snapTriggerMonitor.stopMonitorOnly()
        isRecordingSnapTrigger = false
    }

    private func completeSnapTriggerRecording(modifiers: NSEvent.ModifierFlags, keyCode: UInt16, display: String) {
        print("ShortcutViewModel: snap検知トリガー記録完了 - \(display), keyCode: \(keyCode)")
        let newHotkey = Hotkey(modifiers: modifiers, keyCode: keyCode, keyDisplay: display)

        // 同一キーバリデーション：ハートショートカットと被っていないかチェック
        if actionType == .shortcut,
           newHotkey.keyCode == currentHotkey.keyCode,
           newHotkey.modifiers == currentHotkey.modifiers {
            print("ShortcutViewModel: ⚠️ ハートショートカットと同じキーのため保存をスキップ")
            snapTriggerMonitor.stopMonitorOnly()
            isRecordingSnapTrigger = false
            showSnapTriggerError = "ハート検出ショートカットと同じキーは使えません"
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                showSnapTriggerError = nil
            }
            return
        }

        UserDefaultsManager.shared.save(key: .snapTriggerHotkey, value: newHotkey)
        snapTriggerHotkey = newHotkey
        snapTriggerPreviewHotkey = newHotkey
        showSnapTriggerSuccess = true

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            stopRecordingSnapTrigger()
            showSnapTriggerSuccess = false
            tempSnapKeyDisplay = ""
            tempSnapModifiers = []
            onSnapRecordingComplete?()
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
