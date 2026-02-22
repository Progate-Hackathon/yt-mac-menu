import AppKit
import Combine

@MainActor
final class OnboardingViewModel: ObservableObject {

    // MARK: - Navigation
    @Published var currentStep: Int = 0
    let totalSteps = 8

    // MARK: - Step 1: GitHub設定
    @Published var githubToken: String = ""
    @Published var projectPath: String = ""
    @Published var step2Error: String? = nil
    @Published var isValidating: Bool = false

    // MARK: - Step 2: スナップ検知トリガー
    @Published var snapTriggerHotkey: Hotkey? = nil
    @Published var snapTriggerError: String? = nil
    @Published var isRecordingSnap: Bool = false
    @Published var tempSnapModifiers: NSEvent.ModifierFlags = []
    @Published var tempSnapKeyDisplay: String = ""
    @Published var showSnapSuccess: Bool = false
    @Published var snapPreviewHotkey: Hotkey = Hotkey(modifiers: [], keyCode: 0, keyDisplay: "")

    // MARK: - Step 3: スナップキャリブレーション
    @Published var calibrationCollected: Int = 0
    @Published var calibrationTarget: Int = 15
    @Published var calibrationCompleted: Bool = false
    @Published var isCalibrating: Bool = false

    // MARK: - Step 4: ハートアクション（オンボーディング用・1アクション）
    @Published var actionType: ActionType = .commit
    @Published var commandString: String = ""
    @Published var heartHotkey: Hotkey? = nil
    @Published var isRecordingHeart: Bool = false
    @Published var tempHeartModifiers: NSEvent.ModifierFlags = []
    @Published var tempHeartKeyDisplay: String = ""
    @Published var showHeartSuccess: Bool = false
    @Published var heartPreviewHotkey: Hotkey = Hotkey(modifiers: [], keyCode: 0, keyDisplay: "")

    // MARK: - Step 5: ピースアクション（オンボーディング用・1アクション）
    @Published var peaceActionType: ActionType = .shortcut
    @Published var peaceCommandString: String = ""
    @Published var peaceHotkey: Hotkey? = nil
    @Published var isRecordingPeace: Bool = false
    @Published var tempPeaceModifiers: NSEvent.ModifierFlags = []
    @Published var tempPeaceKeyDisplay: String = ""
    @Published var showPeaceSuccess: Bool = false
    @Published var peacePreviewHotkey: Hotkey = Hotkey(modifiers: [], keyCode: 0, keyDisplay: "")

    // MARK: - Step 6: サムズアップアクション（オンボーディング用・1アクション）
    @Published var thumbsUpActionType: ActionType = .shortcut
    @Published var thumbsUpCommandString: String = ""
    @Published var thumbsUpHotkey: Hotkey? = nil
    @Published var isRecordingThumbsUp: Bool = false
    @Published var tempThumbsUpModifiers: NSEvent.ModifierFlags = []
    @Published var tempThumbsUpKeyDisplay: String = ""
    @Published var showThumbsUpSuccess: Bool = false
    @Published var thumbsUpPreviewHotkey: Hotkey = Hotkey(modifiers: [], keyCode: 0, keyDisplay: "")

    var onSnapRecordingComplete: (() -> Void)?
    var onHeartRecordingComplete: (() -> Void)?
    var onPeaceRecordingComplete: (() -> Void)?
    var onThumbsUpRecordingComplete: (() -> Void)?

    private let snapMonitor = InputMonitorService()
    private let heartMonitor = InputMonitorService()
    private let peaceMonitor = InputMonitorService()
    private let thumbsUpMonitor = InputMonitorService()
    private let gestureRepository: GestureRepositoryProtocol = DependencyContainer.shared.gestureRepository
    private let appCoordinator = DependencyContainer.shared.appCoordinator
    private var calibrationCancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle

    init() {
        loadSavedValues()
        setupSnapMonitor()
        setupHeartMonitor()
        setupPeaceMonitor()
        setupThumbsUpMonitor()
    }

    private func loadSavedValues() {
        githubToken = UserDefaultsManager.shared.get(key: .githubToken, type: String.self) ?? ""
        projectPath = UserDefaultsManager.shared.get(key: .projectFolderPath, type: String.self) ?? ""

        let savedSnap = UserDefaultsManager.shared.get(key: .snapTriggerHotkey, type: Hotkey.self)
        snapTriggerHotkey = savedSnap
        snapPreviewHotkey = savedSnap ?? Hotkey(modifiers: [], keyCode: 0, keyDisplay: "")

        // 各ジェスチャーアクションは新形式（多アクション配列）の先頭から読み込む
        if let heartActions = UserDefaultsManager.shared.get(key: .heartActions, type: [GestureAction].self),
           let first = heartActions.first {
            actionType = first.actionType
            commandString = first.commandString ?? ""
            heartHotkey = first.hotkey
            heartPreviewHotkey = first.hotkey ?? Hotkey(modifiers: [], keyCode: 0, keyDisplay: "")
        }
        if let peaceActions = UserDefaultsManager.shared.get(key: .peaceActions, type: [GestureAction].self),
           let first = peaceActions.first {
            peaceActionType = first.actionType
            peaceCommandString = first.commandString ?? ""
            peaceHotkey = first.hotkey
            peacePreviewHotkey = first.hotkey ?? Hotkey(modifiers: [], keyCode: 0, keyDisplay: "")
        }
        if let thumbsUpActions = UserDefaultsManager.shared.get(key: .thumbsUpActions, type: [GestureAction].self),
           let first = thumbsUpActions.first {
            thumbsUpActionType = first.actionType
            thumbsUpCommandString = first.commandString ?? ""
            thumbsUpHotkey = first.hotkey
            thumbsUpPreviewHotkey = first.hotkey ?? Hotkey(modifiers: [], keyCode: 0, keyDisplay: "")
        }
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

    // MARK: - Step 1: GitHub検証・保存

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

    // MARK: - Step 2: スナップ検知トリガー

    func startRecordingSnap() {
        if isRecordingHeart { stopRecordingHeart() }
        if isRecordingPeace { stopRecordingPeace() }
        if isRecordingThumbsUp { stopRecordingThumbsUp() }
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

    private func setupSnapMonitor() {
        snapMonitor.onUpdate = { [weak self] modifiers, keyDisplay in
            self?.tempSnapModifiers = modifiers
            self?.tempSnapKeyDisplay = keyDisplay
        }
        snapMonitor.onComplete = { [weak self] modifiers, keyCode, display in
            guard let self else { return }
            let hotkey = Hotkey(modifiers: modifiers, keyCode: keyCode, keyDisplay: display)

            // 重複チェック：ハートショートカットと同じキーは使えない
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
                self?.stopRecordingSnap()
                self?.showSnapSuccess = false
                self?.tempSnapKeyDisplay = ""
                self?.tempSnapModifiers = []
                self?.onSnapRecordingComplete?()
            }
        }
    }

    // MARK: - Step 3: スナップキャリブレーション

    func startCalibration() {
        guard !isCalibrating else { return }
        calibrationCollected = 0
        calibrationCompleted = false
        isCalibrating = true
        calibrationCancellables.removeAll()

        gestureRepository.eventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .snapCalibrationProgress(let collected, let target):
                    self.calibrationCollected = collected
                    self.calibrationTarget = target
                case .snapCalibrationCompleted:
                    self.calibrationCollected = self.calibrationTarget
                    self.calibrationCompleted = true
                    self.isCalibrating = false
                    self.appCoordinator.endCalibration()
                    self.calibrationCancellables.removeAll()
                default:
                    break
                }
            }
            .store(in: &calibrationCancellables)

        appCoordinator.beginCalibration()
        gestureRepository.sendCommand(.calibrateSnap)
    }

    func stopCalibrationSubscription() {
        calibrationCancellables.removeAll()
        isCalibrating = false
        appCoordinator.endCalibration()
    }

    // MARK: - Step 4: ハートアクション

    func startRecordingHeart() {
        if isRecordingSnap { stopRecordingSnap() }
        if isRecordingPeace { stopRecordingPeace() }
        if isRecordingThumbsUp { stopRecordingThumbsUp() }
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
        saveHeartAction()
    }

    func saveCommand() {
        saveHeartAction()
    }

    private func setupHeartMonitor() {
        heartMonitor.onUpdate = { [weak self] modifiers, keyDisplay in
            self?.tempHeartModifiers = modifiers
            self?.tempHeartKeyDisplay = keyDisplay
        }
        heartMonitor.onComplete = { [weak self] modifiers, keyCode, display in
            guard let self else { return }
            let hotkey = Hotkey(modifiers: modifiers, keyCode: keyCode, keyDisplay: display)
            heartHotkey = hotkey
            heartPreviewHotkey = hotkey
            saveHeartAction()
            showHeartSuccess = true
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                self?.stopRecordingHeart()
                self?.showHeartSuccess = false
                self?.tempHeartKeyDisplay = ""
                self?.tempHeartModifiers = []
                self?.onHeartRecordingComplete?()
            }
        }
    }

    /// オンボーディングで設定したハートアクションを新形式（多アクション配列）で保存する
    private func saveHeartAction() {
        let action = GestureAction(
            actionType: actionType,
            hotkey: heartHotkey,
            commandString: commandString.isEmpty ? nil : commandString
        )
        UserDefaultsManager.shared.save(key: .heartActions, value: [action])
    }

    // MARK: - Step 5: ピースアクション

    func startRecordingPeace() {
        if isRecordingSnap { stopRecordingSnap() }
        if isRecordingHeart { stopRecordingHeart() }
        if isRecordingThumbsUp { stopRecordingThumbsUp() }
        isRecordingPeace = true
        showPeaceSuccess = false
        tempPeaceModifiers = []
        tempPeaceKeyDisplay = ""
        peaceMonitor.startMonitoring()
    }

    func stopRecordingPeace() {
        peaceMonitor.stopMonitorOnly()
        isRecordingPeace = false
    }

    func savePeaceActionType(_ type: ActionType) {
        peaceActionType = type
        savePeaceAction()
    }

    func savePeaceCommand() {
        savePeaceAction()
    }

    private func setupPeaceMonitor() {
        peaceMonitor.onUpdate = { [weak self] modifiers, keyDisplay in
            self?.tempPeaceModifiers = modifiers
            self?.tempPeaceKeyDisplay = keyDisplay
        }
        peaceMonitor.onComplete = { [weak self] modifiers, keyCode, display in
            guard let self else { return }
            let hotkey = Hotkey(modifiers: modifiers, keyCode: keyCode, keyDisplay: display)
            peaceHotkey = hotkey
            peacePreviewHotkey = hotkey
            savePeaceAction()
            showPeaceSuccess = true
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                self?.stopRecordingPeace()
                self?.showPeaceSuccess = false
                self?.tempPeaceKeyDisplay = ""
                self?.tempPeaceModifiers = []
                self?.onPeaceRecordingComplete?()
            }
        }
    }

    private func savePeaceAction() {
        let action = GestureAction(
            actionType: peaceActionType,
            hotkey: peaceHotkey,
            commandString: peaceCommandString.isEmpty ? nil : peaceCommandString
        )
        UserDefaultsManager.shared.save(key: .peaceActions, value: [action])
    }

    // MARK: - Step 6: サムズアップアクション

    func startRecordingThumbsUp() {
        if isRecordingSnap { stopRecordingSnap() }
        if isRecordingHeart { stopRecordingHeart() }
        if isRecordingPeace { stopRecordingPeace() }
        isRecordingThumbsUp = true
        showThumbsUpSuccess = false
        tempThumbsUpModifiers = []
        tempThumbsUpKeyDisplay = ""
        thumbsUpMonitor.startMonitoring()
    }

    func stopRecordingThumbsUp() {
        thumbsUpMonitor.stopMonitorOnly()
        isRecordingThumbsUp = false
    }

    func saveThumbsUpActionType(_ type: ActionType) {
        thumbsUpActionType = type
        saveThumbsUpAction()
    }

    func saveThumbsUpCommand() {
        saveThumbsUpAction()
    }

    private func setupThumbsUpMonitor() {
        thumbsUpMonitor.onUpdate = { [weak self] modifiers, keyDisplay in
            self?.tempThumbsUpModifiers = modifiers
            self?.tempThumbsUpKeyDisplay = keyDisplay
        }
        thumbsUpMonitor.onComplete = { [weak self] modifiers, keyCode, display in
            guard let self else { return }
            let hotkey = Hotkey(modifiers: modifiers, keyCode: keyCode, keyDisplay: display)
            thumbsUpHotkey = hotkey
            thumbsUpPreviewHotkey = hotkey
            saveThumbsUpAction()
            showThumbsUpSuccess = true
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                self?.stopRecordingThumbsUp()
                self?.showThumbsUpSuccess = false
                self?.tempThumbsUpKeyDisplay = ""
                self?.tempThumbsUpModifiers = []
                self?.onThumbsUpRecordingComplete?()
            }
        }
    }

    private func saveThumbsUpAction() {
        let action = GestureAction(
            actionType: thumbsUpActionType,
            hotkey: thumbsUpHotkey,
            commandString: thumbsUpCommandString.isEmpty ? nil : thumbsUpCommandString
        )
        UserDefaultsManager.shared.save(key: .thumbsUpActions, value: [action])
    }

    // MARK: - Completion

    func complete() {
        UserDefaultsManager.shared.save(key: .onboardingCompleted, value: true)
    }

    deinit {
        let coord = appCoordinator
        let s = snapMonitor
        let h = heartMonitor
        let p = peaceMonitor
        let t = thumbsUpMonitor
        DispatchQueue.main.async {
            coord.endCalibration()
            s.cleanup()
            h.cleanup()
            p.cleanup()
            t.cleanup()
        }
    }
}
