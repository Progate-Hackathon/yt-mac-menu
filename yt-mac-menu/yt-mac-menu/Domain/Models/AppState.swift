import Foundation

enum AppState: Equatable {
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
        case (.listeningForSnap, .listeningForSnap),
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
