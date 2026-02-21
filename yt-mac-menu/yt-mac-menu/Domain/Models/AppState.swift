import Foundation

enum AppState: Equatable {
    case idle           // 接続済み、ショートカット待機中（snap検知は未開始）
    case listeningForSnap
    case snapDetected
    case detectingGesture
    case heartDetected
    case thumbsUpDetected
    case peaceDetected
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
                (.detectingGesture, .detectingGesture),
                (.heartDetected, .heartDetected),
                (.committingData, .committingData),
                (.commitSuccess, .commitSuccess),
                (.shortcutSuccess, .shortcutSuccess),
                (.resetting, .resetting),
                (.peaceDetected, .peaceDetected),
                (.thumbsUpDetected, .thumbsUpDetected):
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
            case .detectingGesture:
                return "Detecting Gesture"
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
            case .thumbsUpDetected:
                return "Thumb Detected"
            case .peaceDetected:
                return "Peace Detected"
        }
    }
}
