import Foundation

enum AppState {
    case idle
    case listeningForSnap
    case snapDetected
    case detectingHeart
    case heartDetected
    case committingData
    case commitSuccess
    case commitError(Error)
    case resetting
    
    var description: String {
        switch self {
        case .idle:
            return "Idle"
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
        case .commitError:
            return "Commit Error"
        case .resetting:
            return "Resetting"
        }
    }
}
