import AppKit
import SwiftUI

final class OnboardingWindowController: NSObject, NSWindowDelegate {
    static let shared = OnboardingWindowController()

    private var window: NSWindow?

    private override init() { super.init() }

    func showIfNeeded() {
        let completed = UserDefaultsManager.shared.getBool(key: .onboardingCompleted)
        guard !completed else { return }
        show()
    }

    private func show() {
        guard window == nil else { window?.makeKeyAndOrderFront(nil); return }

        let contentView = OnboardingView { [weak self] in
            self?.window?.close()
        }

        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 380),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        newWindow.titleVisibility = .hidden
        newWindow.titlebarAppearsTransparent = true
        newWindow.isReleasedWhenClosed = false
        newWindow.contentView = NSHostingView(rootView: contentView)
        newWindow.delegate = self
        newWindow.center()
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = newWindow
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
    }
}
