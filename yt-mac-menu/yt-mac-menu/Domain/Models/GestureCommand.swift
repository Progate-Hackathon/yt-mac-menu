import Foundation

enum GestureCommand: String, Codable {
    // Snap
    case enableSnap = "enable_snap"
    case disableSnap = "disable_snap"
    case calibrateSnap = "calibrate_snap"
    
    // Heart
//    case enableHeart = "enable_heart"
//    case disableHeart = "disable_heart"
//    
    // Thumbs Up
    case enableThumbsUp = "enable_thumbs_up"
    case disableThumbsUp = "disable_thumbs_up"
    
    // Peace
    case enablePeace = "enable_peace"
    case disablePeace = "disable_peace"
    
    // All Gestures
    case enableGesture = "enable_gesture"
    case disableGesture = "disable_gesture"
}
