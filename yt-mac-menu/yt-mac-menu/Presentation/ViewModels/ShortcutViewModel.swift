import SwiftUI
import Combine

@MainActor
final class ShortcutViewModel: ObservableObject {
    
    // MARK: - Recording Context
    
    struct RecordingContext: Equatable {
        let gestureType: GestureType
        let actionIndex: Int
    }

    // MARK: - Properties
    
    // Multi-action arrays (new)
    @Published var heartActions: [GestureAction] = []
    @Published var peaceActions: [GestureAction] = []
    @Published var thumbsUpActions: [GestureAction] = []
    
    // Recording state
    @Published var isRecording: Bool = false
    @Published var showSuccess: Bool = false
    @Published var tempModifiers: NSEvent.ModifierFlags = []
    @Published var tempKeyDisplay: String = ""
    
    private var currentRecordingContext: RecordingContext?

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
        // Load multi-action arrays
        self.heartActions = UserDefaultsManager.shared.get(key: .heartActions, type: [GestureAction].self) ?? []
        self.peaceActions = UserDefaultsManager.shared.get(key: .peaceActions, type: [GestureAction].self) ?? []
        self.thumbsUpActions = UserDefaultsManager.shared.get(key: .thumbsUpActions, type: [GestureAction].self) ?? []
        
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
    
    // MARK: - Multi-Action Management
    
    func actions(for gestureType: GestureType) -> [GestureAction] {
        switch gestureType {
        case .heart: return heartActions
        case .peace: return peaceActions
        case .thumbsUp: return thumbsUpActions
        }
    }
    
    func addAction(for gestureType: GestureType) {
        let actions = self.actions(for: gestureType)
        guard actions.count < GestureAction.maxActionsPerGesture else { return }
        
        let newAction = GestureAction()
        switch gestureType {
        case .heart:
            heartActions.append(newAction)
            saveActions(for: .heart)
        case .peace:
            peaceActions.append(newAction)
            saveActions(for: .peace)
        case .thumbsUp:
            thumbsUpActions.append(newAction)
            saveActions(for: .thumbsUp)
        }
    }
    
    func removeAction(at index: Int, for gestureType: GestureType) {
        switch gestureType {
        case .heart:
            guard heartActions.indices.contains(index) else { return }
            heartActions.remove(at: index)
            saveActions(for: .heart)
        case .peace:
            guard peaceActions.indices.contains(index) else { return }
            peaceActions.remove(at: index)
            saveActions(for: .peace)
        case .thumbsUp:
            guard thumbsUpActions.indices.contains(index) else { return }
            thumbsUpActions.remove(at: index)
            saveActions(for: .thumbsUp)
        }
    }
    
    func updateActionType(_ actionType: ActionType, at index: Int, for gestureType: GestureType) {
        switch gestureType {
        case .heart:
            guard heartActions.indices.contains(index) else { return }
            heartActions[index].actionType = actionType
            saveActions(for: .heart)
        case .peace:
            guard peaceActions.indices.contains(index) else { return }
            peaceActions[index].actionType = actionType
            saveActions(for: .peace)
        case .thumbsUp:
            guard thumbsUpActions.indices.contains(index) else { return }
            thumbsUpActions[index].actionType = actionType
            saveActions(for: .thumbsUp)
        }
    }
    
    func updateCommand(_ command: String, at index: Int, for gestureType: GestureType) {
        switch gestureType {
        case .heart:
            guard heartActions.indices.contains(index) else { return }
            heartActions[index].commandString = command
            saveActions(for: .heart)
        case .peace:
            guard peaceActions.indices.contains(index) else { return }
            peaceActions[index].commandString = command
            saveActions(for: .peace)
        case .thumbsUp:
            guard thumbsUpActions.indices.contains(index) else { return }
            thumbsUpActions[index].commandString = command
            saveActions(for: .thumbsUp)
        }
    }
    
    private func saveActions(for gestureType: GestureType) {
        switch gestureType {
        case .heart:
            UserDefaultsManager.shared.save(key: .heartActions, value: heartActions)
        case .peace:
            UserDefaultsManager.shared.save(key: .peaceActions, value: peaceActions)
        case .thumbsUp:
            UserDefaultsManager.shared.save(key: .thumbsUpActions, value: thumbsUpActions)
        }
        print("ShortcutViewModel: \(gestureType.displayName)アクション保存完了")
    }

    // MARK: - Recorder

    func startRecording(for gestureType: GestureType, actionIndex: Int) {
        print("ShortcutViewModel: startRecording呼び出し - gesture: \(gestureType), index: \(actionIndex)")
        currentRecordingContext = RecordingContext(gestureType: gestureType, actionIndex: actionIndex)
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
        currentRecordingContext = nil
    }

    private func completeRecording(modifiers: NSEvent.ModifierFlags, keyCode: UInt16, display: String) {
        guard let context = currentRecordingContext else { return }
        
        print("ShortcutViewModel: ショートカット記録完了 - \(display), keyCode: \(keyCode), gesture: \(context.gestureType), index: \(context.actionIndex)")
        let newHotkey = Hotkey(modifiers: modifiers, keyCode: keyCode, keyDisplay: display)
        
        // Update the action's hotkey
        switch context.gestureType {
        case .heart:
            guard heartActions.indices.contains(context.actionIndex) else { return }
            heartActions[context.actionIndex].hotkey = newHotkey
            saveActions(for: .heart)
        case .peace:
            guard peaceActions.indices.contains(context.actionIndex) else { return }
            peaceActions[context.actionIndex].hotkey = newHotkey
            saveActions(for: .peace)
        case .thumbsUp:
            guard thumbsUpActions.indices.contains(context.actionIndex) else { return }
            thumbsUpActions[context.actionIndex].hotkey = newHotkey
            saveActions(for: .thumbsUp)
        }
        
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
        // 排他制御：ショートカット記録中なら止める
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
}
