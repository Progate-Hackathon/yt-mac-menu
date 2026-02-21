//
//  OnboardViewModel.swift
//  yt-mac-menu
//
//  Created by cmStudent on 2026/02/21.
//

import SwiftUI
import Combine

final class OnboardViewModel: ObservableObject {

    // MARK: - ShortCutViewModel
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

    // コマンド実行用
    @Published var commandString: String = ""

    var onRecordingComplete: (() -> Void)?
    var onSnapRecordingComplete: (() -> Void)?

    private let inputMonitor = InputMonitorService()
    private let snapTriggerMonitor = InputMonitorService()
    
    // MARK: -SettnigsViewModel
    // MARK: - Properties

    @Published var selectedProjectPath: String = ""
    @Published var githubToken: String = ""
    @Published var baseBranch: String = ""
    @Published var shouldCreatePR: Bool = false
    
    // Branch fetching state
    @Published var availableBranches: [String] = []
    @Published var isFetchingBranches: Bool = false
    @Published var branchFetchError: FetchBranchesUseCaseError?

    @Published var hasUnsavedChanges: Bool = false
    @Published var errorMessage: String?
    @Published var isSaving = false
    @Published var settingsSaved: Bool = false  // 設定が保存されたかを追跡
    
    private let fetchBranchesUseCase: FetchBranchesUseCase

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle

    init(fetchBranchesUseCase: FetchBranchesUseCase) {
        // MARK: - ShortcutViewModel
        self.currentHotkey = UserDefaultsManager.shared.get(key: .hotkeyConfig, type: Hotkey.self)
            ?? Hotkey(modifiers: .option, keyCode: 49, keyDisplay: "Space")
        self.actionType = UserDefaultsManager.shared.get(key: .actionType, type: ActionType.self) ?? .commit
        let savedSnapTrigger = UserDefaultsManager.shared.get(key: .snapTriggerHotkey, type: Hotkey.self)
        self.snapTriggerHotkey = savedSnapTrigger
        self.snapTriggerPreviewHotkey = savedSnapTrigger
            ?? Hotkey(modifiers: [], keyCode: 0, keyDisplay: "")
        self.commandString = UserDefaultsManager.shared.get(key: .commandString, type: String.self) ?? ""

        
        
        // MARK: - SettingsViewModel
        self.fetchBranchesUseCase = fetchBranchesUseCase
        // ShortcutViewModel
        setupRecorderCallbacks()
        setupSnapTriggerCallbacks()
        //MARK: -  ここまで 以降SettingsVewModel
        loadSettings()
        observeSettingChanges()
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

    // MARK: - ShortcutViewModel
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

    func saveCommand() {
        UserDefaultsManager.shared.save(key: .commandString, value: commandString)
        print("ShortcutViewModel: コマンド保存 - \(commandString)")
    }

    func runTestShortcut() {
        KeySender.activatePreviousAppAndSimulateShortcut(
            keyCode: currentHotkey.keyCode,
            modifiers: currentHotkey.modifiers
        )
    }
    
    // MARK: - SettingsViewModel
    // MARK: - Actions (Saving)

    /// Token/Pathの保存（保存ボタン用）
    func saveSettings() async {
        isSaving = true
        defer { isSaving = false }

        guard hasUnsavedChanges else { return }

        guard isProjectPathValid() else { return }
        guard await isGitHubTokenValid() else { return }
        guard isBaseBranchValid() else { return }

        UserDefaultsManager.shared.save(key: .githubToken, value: githubToken)
        UserDefaultsManager.shared.save(key: .projectFolderPath, value: selectedProjectPath)
        UserDefaultsManager.shared.save(key: .baseBranch, value: baseBranch)
        UserDefaultsManager.shared.save(key: .shouldCreatePR, value: shouldCreatePR)

        errorMessage = nil
        hasUnsavedChanges = false
        settingsSaved = true  // 保存完了を通知
        print("DEBUG: Settings saved successfully")
    }
    
    // MARK: - Actions (Branch Fetching)
    
    func fetchBranches() async {
        isFetchingBranches = true
        branchFetchError = nil
        defer { isFetchingBranches = false }
        
        do {
            // First, sync remote branches (git fetch --all)
            try await syncRemoteBranches()
            
            // Then fetch local branches (includes synced remote branches)
            availableBranches = try fetchBranchesUseCase.getBranches()
            
            // Ensure current baseBranch is in the list
            if !baseBranch.isEmpty && !availableBranches.contains(baseBranch) {
                availableBranches.insert(baseBranch, at: 0)
            }
            
            print("DEBUG: Fetched \(availableBranches.count) branches")
        } catch let error as FetchBranchesUseCaseError {
            print("DEBUG: Branch fetch error: \(error.localizedDescription)")
            branchFetchError = error
            availableBranches = []
        } catch {
            print("DEBUG: Unexpected branch fetch error: \(error)")
            availableBranches = []
        }
    }
    
    private func syncRemoteBranches() async throws {
        // Execute: git fetch --all via UseCase
        try fetchBranchesUseCase.fetchRemoteBranches()
    }
}

private extension OnboardViewModel {
    private func observeSettingChanges() {
        Publishers.CombineLatest4($selectedProjectPath, $githubToken, $baseBranch, $shouldCreatePR)
            .removeDuplicates { lhs, rhs in
                lhs.0 == rhs.0 && lhs.1 == rhs.1 && lhs.2 == rhs.2 && lhs.3 == rhs.3
            }
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                hasUnsavedChanges = true
            }
            .store(in: &cancellables)
    }

    @MainActor
    private func loadSettings() {
        self.githubToken = UserDefaultsManager.shared.get(key: .githubToken, type: String.self) ?? ""
        self.selectedProjectPath = UserDefaultsManager.shared.get(key: .projectFolderPath, type: String.self) ?? ""
        self.baseBranch = UserDefaultsManager.shared.get(key: .baseBranch, type: String.self) ?? "main"
        self.shouldCreatePR = UserDefaultsManager.shared.getBool(key: .shouldCreatePR)
        
        // 保存済みの設定がある場合はsettingsSavedをtrueに
        if !githubToken.isEmpty && !selectedProjectPath.isEmpty {
            settingsSaved = true
        }
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

    private func isBaseBranchValid() -> Bool {
        guard !baseBranch.isEmpty else {
            showError("ベースブランチ名が空です")
            return false
        }

        let invalidChars = CharacterSet(charactersIn: " ~^:?*[\\")
        if baseBranch.rangeOfCharacter(from: invalidChars) != nil {
            showError("ブランチ名に無効な文字が含まれています")
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
