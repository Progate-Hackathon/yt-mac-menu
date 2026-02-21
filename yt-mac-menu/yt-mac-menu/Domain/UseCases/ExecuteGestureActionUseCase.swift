import Foundation
import ApplicationServices

@MainActor
final class ExecuteGestureActionUseCase {
    
    // MARK: - Result Types
    
    enum ActionResult {
        case commitSuccess
        case shortcutSuccess
        case commandSuccess(ShellResult)
        case error(Error)
        
        var isSuccess: Bool {
            switch self {
            case .commitSuccess, .shortcutSuccess, .commandSuccess:
                return true
            case .error:
                return false
            }
        }
    }
    
    struct ExecutionSummary {
        let results: [ActionResult]
        
        var totalCount: Int { results.count }
        var successCount: Int { results.filter(\.isSuccess).count }
        var failureCount: Int { results.filter { !$0.isSuccess }.count }
        var allSucceeded: Bool { failureCount == 0 }
        
        var summaryMessage: String {
            if results.isEmpty {
                return "アクションが設定されていません"
            }
            if allSucceeded {
                return "\(totalCount)個のアクションが完了しました"
            }
            return "\(totalCount)個中\(successCount)個成功（\(failureCount)個失敗）"
        }
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
    
    /// Execute all actions for a gesture type sequentially (continue on failure)
    func executeActions(for gestureType: GestureType) async -> ExecutionSummary {
        let actions = loadActions(for: gestureType)
        
        if actions.isEmpty {
            print("ExecuteGestureActionUseCase: \(gestureType.displayName)のアクションが設定されていません")
            return ExecutionSummary(results: [])
        }
        
        print("ExecuteGestureActionUseCase: \(gestureType.displayName) - \(actions.count)個のアクションを実行開始")
        
        var results: [ActionResult] = []
        
        for (index, action) in actions.enumerated() {
            print("ExecuteGestureActionUseCase: アクション\(index + 1)/\(actions.count) - \(action.actionType.displayName)")
            let result = await executeSingleAction(action)
            results.append(result)
            // Continue even on failure
        }
        
        let summary = ExecutionSummary(results: results)
        print("ExecuteGestureActionUseCase: 実行完了 - \(summary.summaryMessage)")
        
        return summary
    }
    
    // MARK: - Private Methods
    
    private func loadActions(for gestureType: GestureType) -> [GestureAction] {
        let key: UserDefaultKeys
        switch gestureType {
        case .heart: key = .heartActions
        case .peace: key = .peaceActions
        case .thumbsUp: key = .thumbsUpActions
        }
        return UserDefaultsManager.shared.get(key: key, type: [GestureAction].self) ?? []
    }
    
    private func executeSingleAction(_ action: GestureAction) async -> ActionResult {
        switch action.actionType {
        case .commit:
            return await executeCommit()
        case .shortcut:
            return await executeShortcut(hotkey: action.hotkey)
        case .command:
            return await executeCommand(command: action.commandString)
        }
    }
    
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
    
    private func executeShortcut(hotkey: Hotkey?) async -> ActionResult {
        // アクセシビリティ権限チェック
        guard AXIsProcessTrusted() else {
            print("ExecuteGestureActionUseCase: アクセシビリティ権限がありません")
            return .error(ActionError.accessibilityPermissionDenied)
        }
        
        guard let hotkey = hotkey else {
            print("ExecuteGestureActionUseCase: ホットキーが設定されていません")
            return .error(ActionError.hotkeyNotConfigured)
        }
        
        print("ExecuteGestureActionUseCase: ショートカット実行 - \(hotkey.displayString)")
        KeySender.activatePreviousAppAndSimulateShortcut(
            keyCode: hotkey.keyCode,
            modifiers: hotkey.modifiers
        )
        
        return .shortcutSuccess
    }
    
    private func executeCommand(command: String?) async -> ActionResult {
        guard let command = command, !command.isEmpty else {
            print("ExecuteGestureActionUseCase: コマンドが設定されていません")
            return .error(ActionError.commandNotConfigured)
        }
        
        print("ExecuteGestureActionUseCase: コマンド実行 - \(command)")
        let result = await ShellExecutor.execute(command: command)
        
        if result.isSuccess {
            print("ExecuteGestureActionUseCase: コマンド成功")
            return .commandSuccess(result)
        } else {
            print("ExecuteGestureActionUseCase: コマンド失敗 - exit code: \(result.exitCode)")
            return .error(ActionError.commandFailed(exitCode: result.exitCode, stderr: result.stderr))
        }
    }
}
