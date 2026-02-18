import AppKit

struct Hotkey: Codable, Equatable {
    // 保存用: 数値として保存する
    var modifiersRaw: UInt
    var keyCode: UInt16
    var keyDisplay: String
    
    // アプリ内で使うときはこれを呼ぶ
    var modifiers: NSEvent.ModifierFlags {
        get { NSEvent.ModifierFlags(rawValue: modifiersRaw) }
        set { modifiersRaw = newValue.rawValue }
    }
    
    init(modifiers: NSEvent.ModifierFlags, keyCode: UInt16, keyDisplay: String) {
        self.modifiersRaw = modifiers.rawValue
        self.keyCode = keyCode
        self.keyDisplay = keyDisplay
    }
    
    // 表示用
    var displayString: String {
        var string = ""
        if modifiers.contains(.control) { string += "⌃ " }
        if modifiers.contains(.option) { string += "⌥ " }
        if modifiers.contains(.shift) { string += "⇧ " }
        if modifiers.contains(.command) { string += "⌘ " }
        string += keyDisplay
        return string
    }
}
