import Foundation

enum AppState: Equatable {
    case idle           // 接続済み、ショートカット待機中（snap検知は未開始）
    case listeningForSnap
    case snapDetected
    case detectingHeart
    case heartDetected
    case committingData
    case commitSuccess
    case shortcutSuccess
    case commitError(Error)
    case resetting
    
    static func == (lhs: AppState, rhs: AppState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.listeningForSnap, .listeningForSnap),
             (.snapDetected, .snapDetected),
             (.detectingHeart, .detectingHeart),
             (.heartDetected, .heartDetected),
             (.committingData, .committingData),
             (.commitSuccess, .commitSuccess),
             (.shortcutSuccess, .shortcutSuccess),
             (.resetting, .resetting):
            return true
        case (.commitError(let lhsError), .commitError(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
    
    var description: String {
        switch self {
        case .idle:
            return "Idle (Waiting for Shortcut)"
        case .listeningForSnap:
            return "Listening for Snap"
        case .snapDetected:
            return "Snap Detected"
        case .detectingHeart:
            return "Detecting Heart"
        case .heartDetected:
            return "Heart Detected"
        case .committingData:
            return "Committing Data"
        case .commitSuccess:
            return "Commit Success"
        case .shortcutSuccess:
            return "Shortcut Success"
        case .commitError:
            return "Commit Error"
        case .resetting:
            return "Resetting"
        }
    }
}
