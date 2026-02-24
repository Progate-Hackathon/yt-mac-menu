import AppKit
import Carbon

/// Carbon RegisterEventHotKey を使う権限不要のグローバルホットキーサービス
final class GlobalHotkeyService {
    var onTrigger: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var userDefaultsObserver: Any?

    func start() {
        installEventHandler()
        registerCurrentHotkey()

        // ホットキー設定変更を検知して自動再登録
        userDefaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateHotkey()
        }
    }

    func stop() {
        if let obs = userDefaultsObserver {
            NotificationCenter.default.removeObserver(obs)
            userDefaultsObserver = nil
        }
        unregisterHotkey()
        if let handler = eventHandlerRef {
            RemoveEventHandler(handler)
            eventHandlerRef = nil
        }
        print("GlobalHotkeyService: 監視停止")
    }

    func updateHotkey() {
        unregisterHotkey()
        registerCurrentHotkey()
    }

    private func installEventHandler() {
        guard eventHandlerRef == nil else { return }
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, _, userInfo) -> OSStatus in
                guard let userInfo else { return OSStatus(eventNotHandledErr) }
                let service = Unmanaged<GlobalHotkeyService>.fromOpaque(userInfo).takeUnretainedValue()
                DispatchQueue.main.async { service.onTrigger?() }
                return noErr
            },
            1, &eventType, selfPtr, &eventHandlerRef
        )
    }

    private func registerCurrentHotkey() {
        guard let hotkey = UserDefaultsManager.shared.get(key: .snapTriggerHotkey, type: Hotkey.self) else {
            #if DEBUG
            print("GlobalHotkeyService: snapTriggerHotkey が未設定です")
            #endif
            return
        }
        let carbonModifiers = nsModifiersToCarbon(
            hotkey.modifiers.intersection([.command, .option, .control, .shift])
        )
        let hotKeyID = EventHotKeyID(signature: OSType(0x686B534E), id: 1)
        let status = RegisterEventHotKey(
            UInt32(hotkey.keyCode), carbonModifiers,
            hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef
        )
        if status == noErr {
            print("GlobalHotkeyService: ✅ ホットキー登録成功 - \(hotkey.displayString)")
        } else {
            print("GlobalHotkeyService: ⚠️ ホットキー登録失敗 status=\(status)")
        }
    }

    private func unregisterHotkey() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
    }

    private func nsModifiersToCarbon(_ modifiers: NSEvent.ModifierFlags) -> UInt32 {
        var result: UInt32 = 0
        if modifiers.contains(.command) { result |= UInt32(cmdKey) }
        if modifiers.contains(.option)  { result |= UInt32(optionKey) }
        if modifiers.contains(.control) { result |= UInt32(controlKey) }
        if modifiers.contains(.shift)   { result |= UInt32(shiftKey) }
        return result
    }
}
