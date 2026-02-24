import AppKit

extension NSEvent.ModifierFlags {
    var formattedString: String {
        var keys: [String] = []
        if contains(.control) { keys.append("⌃") }
        if contains(.option)  { keys.append("⌥") }
        if contains(.shift)   { keys.append("⇧") }
        if contains(.command) { keys.append("⌘") }
        return keys.joined(separator: " ")
    }
}
