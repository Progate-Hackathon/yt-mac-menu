import Foundation

enum GestureEvent {
    // New nested format
    case audioDetected(AudioType)
    case gestureDetected(GestureType)
    
    // System events
    case handCount(Int)
    case connected
    case disconnected
}

enum EventType: String, Decodable {
    case audio
    case gesture
    case handCount = "hand_count"
}

enum AudioType: String, Decodable {
    case snap
}

enum GestureType: String, Decodable {
    case heart
    case thumbsUp = "thumbs_up"
    case peace
}
