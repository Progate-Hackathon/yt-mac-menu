import Foundation

@MainActor
final class ExecuteGestureActionUseCase {
    
    // MARK: - Configuration
    
    struct ActionConfig {
        let hotkeyKey: UserDefaultKeys
        let commandKey: UserDefaultKeys
        let actionTypeKey: UserDefaultKeys
    }
    
    enum ActionResult {
        case commitSuccess
        case shortcutSuccess
        case commandSuccess(ShellResult)
        case error(Error)
    }
    
    // MARK: - Dependencies
    
    private let sendCommitDataUseCase: SendCommitDataUseCase
    private let stashChangesUseCase: StashChangesUseCase
    
    init(
        sendCommitDataUseCase: SendCommitDataUseCase,
        stashChangesUseCase: StashChangesUseCase
    ) {
        self.sendCommitDataUseCase = sendCommitDataUseCase
        self.stashChangesUseCase = stashChangesUseCase
    }
    
    // MARK: - Public API
    
    /// Execute action based on config (reads action type from UserDefaults)
    func executeAction(config: ActionConfig) async -> ActionResult {
        let actionType = UserDefaultsManager.shared.get(
            key: config.actionTypeKey,
            type: ActionType.self
        ) ?? .shortcut
        
        print("ExecuteGestureActionUseCase: アクション実行開始 - \(actionType.displayName)")
        
        switch actionType {
        case .commit:
            return await executeCommit()
        case .shortcut:
            return await executeShortcut(hotkeyKey: config.hotkeyKey)
        case .command:
            return await executeCommand(commandKey: config.commandKey)
        }
    }
    
    // MARK: - Private Methods
    
    private func executeCommit() async -> ActionResult {
        print("ExecuteGestureActionUseCase: コミット実行")
        do {
            _ = try await sendCommitDataUseCase.sendCommitData()
            print("ExecuteGestureActionUseCase: コミット成功 Stashし始めます。")
            
            try stashChangesUseCase.stashChanges()

            return .commitSuccess
        } catch {
            print("ExecuteGestureActionUseCase: コミット失敗 - \(error.localizedDescription)")
            return .error(error)
        }
    }
    
    private func executeShortcut(hotkeyKey: UserDefaultKeys) async -> ActionResult {
        guard let hotkey = UserDefaultsManager.shared.get(
            key: hotkeyKey,
            type: Hotkey.self
        ) else {
            print("ExecuteGestureActionUseCase: ホットキーが設定されていません")
            return .error(NSError(
                domain: "ExecuteGestureAction",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "ホットキーが設定されていません"]
            ))
        }
        
        print("ExecuteGestureActionUseCase: ショートカット実行 - \(hotkey.displayString)")
        KeySender.activatePreviousAppAndSimulateShortcut(
            keyCode: hotkey.keyCode,
            modifiers: hotkey.modifiers
        )
        
        return .shortcutSuccess
    }
    
    private func executeCommand(commandKey: UserDefaultKeys) async -> ActionResult {
        guard let command = UserDefaultsManager.shared.get(
            key: commandKey,
            type: String.self
        ), !command.isEmpty else {
            print("ExecuteGestureActionUseCase: コマンドが設定されていません")
            return .error(NSError(
                domain: "ExecuteGestureAction",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "コマンドが設定されていません"]
            ))
        }
        
        print("ExecuteGestureActionUseCase: コマンド実行 - \(command)")
        let result = await ShellExecutor.execute(command: command)
        
        if result.isSuccess {
            print("ExecuteGestureActionUseCase: コマンド成功")
            return .commandSuccess(result)
        } else {
            print("ExecuteGestureActionUseCase: コマンド失敗 - exit code: \(result.exitCode)")
            return .error(NSError(
                domain: "ShellExecutor",
                code: Int(result.exitCode),
                userInfo: [NSLocalizedDescriptionKey: result.stderr.isEmpty ?
                    "コマンドが失敗しました (exit \(result.exitCode))" : result.stderr]
            ))
        }
    }
}
