import Foundation

/// ハート検出時に実行するアクションの種類
enum ActionType: String, Codable, CaseIterable {
    case commit = "commit"
    case shortcut = "shortcut"
    case command = "command"
    
    var displayName: String {
        switch self {
        case .commit:
            return "コミット"
        case .shortcut:
            return "ショートカット"
        case .command:
            return "コマンド実行"
        }
    }
    
    var description: String {
        switch self {
        case .commit:
            return "変更内容をAIが要約してGitHubにコミットします"
        case .shortcut:
            return "直前に使用していたアプリでショートカットキーを実行します"
        case .command:
            return "ハート検出時に指定したシェルコマンドを実行します"
        }
    }
}
