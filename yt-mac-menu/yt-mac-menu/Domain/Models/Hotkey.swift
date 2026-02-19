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
        let mod = modifiers.formattedString
        return mod.isEmpty ? keyDisplay : mod + " " + keyDisplay
    }
}
