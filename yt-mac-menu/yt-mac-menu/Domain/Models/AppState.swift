import Foundation

enum AppState {
    case idle
    case listeningForSnap
    case snapDetected
    case detectingHeart
    case heartDetected
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
        case .resetting:
            return "Resetting"
        }
    }
}
