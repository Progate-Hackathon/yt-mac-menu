import AppKit
import SwiftUI

class FloatingWindowController: NSObject, NSWindowDelegate {
    static let shared = FloatingWindowController()

    private var window: NSWindow?

    private override init() {
        super.init()
    }

    func open() {
        if let existingWindow = window {
            existingWindow.makeKeyAndOrderFront(nil)
            return
        }

        guard let screen = NSScreen.main else { return }
        let screenRect = screen.visibleFrame
        let defaultSize = CGSize(width: 320, height: 240)
        let padding: CGFloat = 5

        let newWindow = NSWindow(
            contentRect: NSRect(
                x: screenRect.midX - defaultSize.width / 2,
                y: screenRect.maxY - defaultSize.height - padding,
                width: defaultSize.width,
                height: defaultSize.height
            ),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        newWindow.titleVisibility = .hidden
        newWindow.titlebarAppearsTransparent = true
        newWindow.level = .floating
        newWindow.isReleasedWhenClosed = false

        // GestureCameraView の PreferenceKey でウィンドウサイズを受け取るラッパー
        let rootView = GestureCameraView()
            .onPreferenceChange(WindowSizeKey.self) { [weak newWindow] size in
                guard let size, let window = newWindow else { return }
                DispatchQueue.main.async {
                    let screen = NSScreen.main ?? NSScreen.screens[0]
                    let screenRect = screen.visibleFrame
                    let origin = NSPoint(
                        x: screenRect.midX - size.width / 2,
                        y: screenRect.maxY - size.height - padding
                    )
                    window.setFrame(NSRect(origin: origin, size: size), display: true, animate: false)
                }
            }

        newWindow.contentView = NSHostingView(rootView: rootView)
        newWindow.delegate = self
        newWindow.makeKeyAndOrderFront(nil)
        self.window = newWindow
    }

    func close() {
        window?.close()
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        return true
    }

    func windowWillClose(_ notification: Notification) {
        DependencyContainer.shared.appCoordinator.handleWindowClose()
        window = nil
    }
}
