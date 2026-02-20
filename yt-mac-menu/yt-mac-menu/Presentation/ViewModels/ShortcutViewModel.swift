import SwiftUI
import Combine

@MainActor
final class ShortcutViewModel: ObservableObject {

    // MARK: - Properties

    @Published var currentHotkey: Hotkey
    @Published var actionType: ActionType
    @Published var isRecording: Bool = false
    @Published var isSuccessState: Bool = false
    @Published var tempModifiers: NSEvent.ModifierFlags = []
    @Published var tempKeyDisplay: String = ""

    private let inputMonitor = InputMonitorService()

    // MARK: - Lifecycle

    init() {
        self.currentHotkey = UserDefaultsManager.shared.get(key: .hotkeyConfig, type: Hotkey.self)
            ?? Hotkey(modifiers: .option, keyCode: 49, keyDisplay: "Space")
        self.actionType = UserDefaultsManager.shared.get(key: .actionType, type: ActionType.self) ?? .commit

        setupRecorderCallbacks()
    }

    deinit {
        Task { @MainActor in
            inputMonitor.stopMonitoring()
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
        isRecording = true
        isSuccessState = false
        tempModifiers = []
        tempKeyDisplay = ""
        inputMonitor.startMonitoring()
    }

    func stopRecording() {
        inputMonitor.stopMonitoring()
        isRecording = false
    }

    private func completeRecording(modifiers: NSEvent.ModifierFlags, keyCode: UInt16, display: String) {
        print("ShortcutViewModel: ショートカット記録完了 - \(display), keyCode: \(keyCode), modifiers: \(modifiers)")
        let newHotkey = Hotkey(modifiers: modifiers, keyCode: keyCode, keyDisplay: display)
        print("ShortcutViewModel: 保存前のホットキー: \(currentHotkey.displayString)")
        saveHotkey(newHotkey)
        currentHotkey = newHotkey
        print("ShortcutViewModel: 保存後のホットキー: \(currentHotkey.displayString)")
        isSuccessState = true

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            stopRecording()
            isSuccessState = false
            tempKeyDisplay = ""
            tempModifiers = []
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
