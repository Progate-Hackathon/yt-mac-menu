import SwiftUI

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
        let newHotkey = Hotkey(modifiers: modifiers, keyCode: keyCode, keyDisplay: display)
        saveHotkey(newHotkey)
        currentHotkey = newHotkey
        isSuccessState = true

        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            stopRecording()
            tempKeyDisplay = ""
            tempModifiers = []
        }
    }

    // MARK: - Actions

    func saveHotkey(_ hotkey: Hotkey) {
        UserDefaultsManager.shared.save(key: .hotkeyConfig, value: hotkey)
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
