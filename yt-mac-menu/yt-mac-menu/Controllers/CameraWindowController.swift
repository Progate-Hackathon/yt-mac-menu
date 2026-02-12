import AppKit
import SwiftUI

class CameraWindowController: NSObject, NSWindowDelegate {
    static let shared = CameraWindowController()
    
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
        
        let width: CGFloat = 320
        let height: CGFloat = 240
        
        let padding: CGFloat = 5

        let xPos = screenRect.maxX - width - padding
        let yPos = screenRect.maxY - height - padding
        
        let newWindow = NSWindow(
            contentRect: NSRect(x: xPos, y: yPos, width: width, height: height),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        newWindow.titleVisibility = .hidden
        newWindow.titlebarAppearsTransparent = true
        newWindow.level = .floating
        newWindow.isReleasedWhenClosed = false
        
        newWindow.contentView = NSHostingView(rootView: GestureCameraView())
//        newWindow.contentView = NSHostingView(rootView: GestureDetectionView())
        
        newWindow.delegate = self
        newWindow.makeKeyAndOrderFront(nil)
        
        self.window = newWindow
    }
    
    func windowWillClose(_ notification: Notification) {
        window = nil
    }
}
