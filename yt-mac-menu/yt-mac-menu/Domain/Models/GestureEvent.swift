import Foundation

enum GestureEvent {
    // New nested format
    case audioDetected(AudioType)
    case gestureDetected(GestureType)
    case gestureLost(GestureType)
    
    // Snap calibration events
    case snapCalibrationProgress(collected: Int, target: Int)
    case snapCalibrationCompleted
    
    // System events
    case handCount(Int)
    case connected
    case disconnected
}

enum EventType: String, Decodable {
    case audio
    case gesture
    case gestureLost = "gesture_lost"
    case handCount = "hand_count"
    case snapCalibration = "snap_calibration"
}

enum AudioType: String, Decodable {
    case snap
}

enum GestureType: String, Codable, Equatable {
    case heart
    case thumbsUp = "thumbs_up"
    case peace
    
    var displayName: String {
        switch self {
        case .heart:
            return "ハート"
        case .thumbsUp:
            return "サムズアップ"
        case .peace:
            return "ピース"
        }
    }
    
    var emoji: String {
        switch self {
        case .heart:
            return "❤️"
        case .thumbsUp:
            return "👍"
        case .peace:
            return "✌️"
        }
    }
}
