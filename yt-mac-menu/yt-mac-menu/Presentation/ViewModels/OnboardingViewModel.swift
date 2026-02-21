import AppKit
import Combine

@MainActor
final class OnboardingViewModel: ObservableObject {

    // MARK: - Step management
    @Published var currentStep: Int = 0
    let totalSteps = 5

    // MARK: - Step 2: GitHub設定
    @Published var githubToken: String = ""
    @Published var projectPath: String = ""
    @Published var step2Error: String? = nil
    @Published var isValidating: Bool = false

    // MARK: - Step 3: スナップ検知トリガー
    @Published var snapTriggerHotkey: Hotkey? = nil
    @Published var isRecordingSnap: Bool = false
    @Published var tempSnapModifiers: NSEvent.ModifierFlags = []
    @Published var tempSnapKeyDisplay: String = ""
    @Published var showSnapSuccess: Bool = false
    @Published var snapPreviewHotkey: Hotkey = Hotkey(modifiers: [], keyCode: 0, keyDisplay: "")

    // MARK: - Step 3: スナップ検知トリガー（エラー）
    @Published var snapTriggerError: String? = nil

    // MARK: - Step 4: ハートアクション
    @Published var actionType: ActionType = .commit
    @Published var commandString: String = ""
    @Published var heartHotkey: Hotkey? = nil
    @Published var isRecordingHeart: Bool = false
    @Published var tempHeartModifiers: NSEvent.ModifierFlags = []
    @Published var tempHeartKeyDisplay: String = ""
    @Published var showHeartSuccess: Bool = false
    @Published var heartPreviewHotkey: Hotkey = Hotkey(modifiers: [], keyCode: 0, keyDisplay: "")

    private let snapMonitor = InputMonitorService()
    private let heartMonitor = InputMonitorService()

    var onSnapRecordingComplete: (() -> Void)?
    var onHeartRecordingComplete: (() -> Void)?

    // MARK: - Lifecycle

    init() {
        loadSavedValues()
        setupSnapMonitor()
        setupHeartMonitor()
    }

    private func loadSavedValues() {
        githubToken = UserDefaultsManager.shared.get(key: .githubToken, type: String.self) ?? ""
        projectPath = UserDefaultsManager.shared.get(key: .projectFolderPath, type: String.self) ?? ""
        snapTriggerHotkey = UserDefaultsManager.shared.get(key: .snapTriggerHotkey, type: Hotkey.self)
        snapPreviewHotkey = snapTriggerHotkey ?? Hotkey(modifiers: [], keyCode: 0, keyDisplay: "")
        actionType = UserDefaultsManager.shared.get(key: .actionType, type: ActionType.self) ?? .commit
        commandString = UserDefaultsManager.shared.get(key: .commandString, type: String.self) ?? ""
        heartHotkey = UserDefaultsManager.shared.get(key: .hotkeyConfig, type: Hotkey.self)
        heartPreviewHotkey = heartHotkey ?? Hotkey(modifiers: [], keyCode: 0, keyDisplay: "")
    }

    // MARK: - Navigation

    func next() {
        guard currentStep < totalSteps - 1 else { return }
        currentStep += 1
    }

    func back() {
        guard currentStep > 0 else { return }
        currentStep -= 1
    }

    // MARK: - Step 2: Validation & Save

    func validateAndSaveGitHub() async -> Bool {
        isValidating = true
        step2Error = nil
        defer { isValidating = false }

        // プロジェクトパスの検証（SettingsViewModelと同じ）
        guard !projectPath.isEmpty else { step2Error = "プロジェクトパスが空です"; return false }

        let fm = FileManager.default
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: projectPath, isDirectory: &isDir) else {
            step2Error = "指定されたパスは存在しません"; return false
        }
        guard isDir.boolValue else {
            step2Error = "指定されたパスはフォルダではありません"; return false
        }

        let gitPath = (projectPath as NSString).appendingPathComponent(".git")
        var isGitDir: ObjCBool = false
        guard fm.fileExists(atPath: gitPath, isDirectory: &isGitDir), isGitDir.boolValue else {
            step2Error = "このフォルダはGitリポジトリではありません"; return false
        }

        // GitHubトークンの検証（SettingsViewModelと同じ）
        guard !githubToken.isEmpty else { step2Error = "GitHubトークンを入力してください"; return false }

        do {
            let valid = try await GitHubAPIClient.shared.isValidToken(githubToken)
            guard valid else { step2Error = "無効なGitHubトークンです"; return false }
        } catch GitHubTokenError.network(let networkError) {
            step2Error = "ネットワークの問題が発生しました。やり直してください。"
            print("Tokenの検証に失敗(NetworkError): \(networkError.localizedDescription)")
            return false
        } catch GitHubTokenError.invalidResponse {
            step2Error = "エラーが発生しました。やり直してください。"
            return false
        } catch {
            step2Error = "無効なトークンです"; return false
        }

        UserDefaultsManager.shared.save(key: .githubToken, value: githubToken)
        UserDefaultsManager.shared.save(key: .projectFolderPath, value: projectPath)
        return true
    }

    // MARK: - Step 3: Snap trigger recording

    private func setupSnapMonitor() {
        snapMonitor.onUpdate = { [weak self] modifiers, keyDisplay in
            self?.tempSnapModifiers = modifiers
            self?.tempSnapKeyDisplay = keyDisplay
        }
        snapMonitor.onComplete = { [weak self] modifiers, keyCode, display in
            guard let self else { return }
            let hotkey = Hotkey(modifiers: modifiers, keyCode: keyCode, keyDisplay: display)

            // 同一キーバリデーション：ハートショートカットと被っていないかチェック
            if actionType == .shortcut,
               let heartHotkey,
               hotkey.keyCode == heartHotkey.keyCode,
               hotkey.modifiers == heartHotkey.modifiers {
                snapMonitor.stopMonitorOnly()
                isRecordingSnap = false
                snapTriggerError = "ハート検出ショートカットと同じキーは使えません"
                Task { @MainActor [weak self] in
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    self?.snapTriggerError = nil
                }
                return
            }

            UserDefaultsManager.shared.save(key: .snapTriggerHotkey, value: hotkey)
            snapTriggerHotkey = hotkey
            snapPreviewHotkey = hotkey
            showSnapSuccess = true
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                self?.snapMonitor.stopMonitorOnly()
                self?.isRecordingSnap = false
                self?.showSnapSuccess = false
                self?.tempSnapKeyDisplay = ""
                self?.tempSnapModifiers = []
                self?.onSnapRecordingComplete?()
            }
        }
    }

    func startRecordingSnap() {
        if isRecordingHeart { stopRecordingHeart() }
        isRecordingSnap = true
        showSnapSuccess = false
        tempSnapModifiers = []
        tempSnapKeyDisplay = ""
        snapMonitor.startMonitoring()
    }

    func stopRecordingSnap() {
        snapMonitor.stopMonitorOnly()
        isRecordingSnap = false
    }

    // MARK: - Step 4: Heart hotkey recording

    private func setupHeartMonitor() {
        heartMonitor.onUpdate = { [weak self] modifiers, keyDisplay in
            self?.tempHeartModifiers = modifiers
            self?.tempHeartKeyDisplay = keyDisplay
        }
        heartMonitor.onComplete = { [weak self] modifiers, keyCode, display in
            guard let self else { return }
            let hotkey = Hotkey(modifiers: modifiers, keyCode: keyCode, keyDisplay: display)
            UserDefaultsManager.shared.save(key: .hotkeyConfig, value: hotkey)
            heartHotkey = hotkey
            heartPreviewHotkey = hotkey
            showHeartSuccess = true
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                self?.heartMonitor.stopMonitorOnly()
                self?.isRecordingHeart = false
                self?.showHeartSuccess = false
                self?.tempHeartKeyDisplay = ""
                self?.tempHeartModifiers = []
                self?.onHeartRecordingComplete?()
            }
        }
    }

    func startRecordingHeart() {
        if isRecordingSnap { stopRecordingSnap() }
        isRecordingHeart = true
        showHeartSuccess = false
        tempHeartModifiers = []
        tempHeartKeyDisplay = ""
        heartMonitor.startMonitoring()
    }

    func stopRecordingHeart() {
        heartMonitor.stopMonitorOnly()
        isRecordingHeart = false
    }

    func saveActionType(_ type: ActionType) {
        actionType = type
        UserDefaultsManager.shared.save(key: .actionType, value: type)
    }

    func saveCommand() {
        UserDefaultsManager.shared.save(key: .commandString, value: commandString)
    }

    // MARK: - Completion

    func complete() {
        UserDefaultsManager.shared.save(key: .onboardingCompleted, value: true)
    }

    deinit {
        let s = snapMonitor
        let h = heartMonitor
        DispatchQueue.main.async {
            s.cleanup()
            h.cleanup()
        }
    }
}
