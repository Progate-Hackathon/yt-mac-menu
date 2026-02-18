import SwiftUI
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    
    // MARK: - Properties
    
    // Settings Data
    @Published var selectedProjectPath: String = ""
    @Published var githubToken: String = ""
    @Published var currentHotkey: Hotkey
    @Published var actionType: ActionType
    
    // UI State
    @Published var hasUnsavedChanges: Bool = false
    @Published var errorMessage: String?
    @Published var isSaving = false
    
    // Recorder State
    @Published var isRecording: Bool = false
    @Published var isSuccessState: Bool = false
    @Published var tempModifiers: NSEvent.ModifierFlags = []
    @Published var tempKeyDisplay: String = ""
    
    // Dependencies
    private let inputMonitor = InputMonitorService()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Lifecycle
    
    init() {
        // 初期値ロード
        self.githubToken = UserDefaultsManager.shared.get(key: .githubToken) ?? ""
        self.selectedProjectPath = UserDefaultsManager.shared.get(key: .projectFolderPath) ?? ""
        self.currentHotkey = UserDefaultsManager.shared.get(key: .hotkeyConfig, type: Hotkey.self)
            ?? Hotkey(modifiers: .option, keyCode: 49, keyDisplay: "Space")
        self.actionType = UserDefaultsManager.shared.get(key: .actionType, type: ActionType.self) ?? .commit
        
        setupRecorderCallbacks()
        setupChangeObserver()
    }
    
    // MARK: - Setup
    
    private func setupChangeObserver() {
        // Token/Pathの変更を監視してunsavedフラグを立てる
        Publishers.CombineLatest($selectedProjectPath, $githubToken)
            .dropFirst()
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .removeDuplicates { $0.0 == $1.0 && $0.1 == $1.1 }
            .sink { [weak self] _ in
                self?.hasUnsavedChanges = true
            }
            .store(in: &cancellables)
    }
    
    private func setupRecorderCallbacks() {
        inputMonitor.onUpdate = { [weak self] modifiers, keyDisplay in
            self?.tempModifiers = modifiers
            self?.tempKeyDisplay = keyDisplay
        }
        
        inputMonitor.onComplete = { [weak self] modifiers, keyCode, display in
            self?.completeRecording(modifiers: modifiers, keyCode: keyCode, display: display)
        }
    }

    // MARK: - Actions (Saving)
    
    /// Token/Pathの保存（保存ボタン用）
    func saveSettings() async {
        isSaving = true
        defer { isSaving = false }
        
        guard hasUnsavedChanges else { return }
        
        // Validation
        guard isProjectPathValid() else { return }
        guard await isGitHubTokenValid() else { return }
        
        UserDefaultsManager.shared.save(key: .githubToken, value: githubToken)
        UserDefaultsManager.shared.save(key: .projectFolderPath, value: selectedProjectPath)
        
        errorMessage = nil
        hasUnsavedChanges = false
        print("DEBUG: Settings saved successfully")
    }
    
    private func saveHotkey(_ hotkey: Hotkey) {
        UserDefaultsManager.shared.save(key: .hotkeyConfig, value: hotkey)
        print("DEBUG: Hotkey saved: \(hotkey.displayString)")
    }
    
    func saveActionType(_ type: ActionType) {
        UserDefaultsManager.shared.save(key: .actionType, value: type)
        actionType = type
        print("DEBUG: ActionType saved: \(type.displayName)")
    }
    
    // MARK: - Actions (Recorder)
    
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
        // 新しいHotkeyを作成して即座に保存
        let newHotkey = Hotkey(modifiers: modifiers, keyCode: keyCode, keyDisplay: display)
        saveHotkey(newHotkey)
        
        // プロパティ更新
        currentHotkey = newHotkey
        isSuccessState = true
        
        // 1秒後にUIをリセット（@MainActorクラス内のTaskは自動的にMainActorを継承）
        Task {
            try? await Task.sleep(for: .seconds(1))
            stopRecording()
            tempKeyDisplay = ""
            tempModifiers = []
        }
    }
    
    // MARK: - Actions (Test)
    
    func runTestShortcut() {
        print("Executing shortcut: \(currentHotkey.displayString)")
        KeySender.activatePreviousAppAndSimulateShortcut(keyCode: currentHotkey.keyCode, modifiers: currentHotkey.modifiers)
    }
    
    // MARK: - Validation
    
    private func isProjectPathValid() -> Bool {
        guard !selectedProjectPath.isEmpty else {
            showError("プロジェクトパスが空です")
            return false
        }
        
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        
        guard fileManager.fileExists(atPath: selectedProjectPath, isDirectory: &isDirectory) else {
            showError("指定されたパスは存在しません")
            return false
        }
        
        guard isDirectory.boolValue else {
            showError("指定されたパスはフォルダではありません")
            return false
        }
        
        let gitPath = (selectedProjectPath as NSString).appendingPathComponent(".git")
        var isGitDirectory: ObjCBool = false
        
        guard fileManager.fileExists(atPath: gitPath, isDirectory: &isGitDirectory),
              isGitDirectory.boolValue else {
            showError("このフォルダはGitリポジトリではありません")
            return false
        }
        
        return true
    }
    
    private func isGitHubTokenValid() async -> Bool {
        do {
            return try await GitHubAPIClient.shared.isValidToken(githubToken)
        } catch GitHubTokenError.network(let networkError) {
            showError("ネットワークの問題が発生しました。やり直してください。")
            print("Tokenの検証に失敗(NetworkError): \(networkError.localizedDescription)")
        } catch GitHubTokenError.invalidResponse {
            showError("エラーが発生しました。やり直してください。")
            print("Tokenの検証に失敗: Invalid Response")
        } catch {
            showError("無効なトークンです")
        }
        return false
    }
    
    private func showError(_ message: String) {
        errorMessage = message
    }
}
