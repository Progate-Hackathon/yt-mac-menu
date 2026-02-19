import AppKit
import SwiftUI
import Combine

class FloatingWindowController: NSObject, NSWindowDelegate {
    static let shared = FloatingWindowController()
    
    private var window: NSWindow?
    private var cancellables = Set<AnyCancellable>()
    private var isClosingProgrammatically = false
    
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
        
        let xPos = (screenRect.maxX/2) - (width/2)
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
        
        newWindow.delegate = self
        newWindow.makeKeyAndOrderFront(nil)
        
        self.window = newWindow
    }
    
    func close() {
        isClosingProgrammatically = true
        window?.close()
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        let coordinator = DependencyContainer.shared.appCoordinator
        
        // ユーザーが手動で閉じる場合は常に許可
        if !isClosingProgrammatically {
            print("FloatingWindowController: ユーザーによる手動クローズを許可")
            return true
        }
        
        // プログラムによるクローズの場合、エラー状態なら防止
        if case .commitError = coordinator.currentState {
            print("FloatingWindowController: エラー状態のため自動クローズを防止")
            isClosingProgrammatically = false // フラグをリセット
            return false
        }
        
        return true
    }
    
    func windowWillClose(_ notification: Notification) {
        // ウィンドウが閉じるときは常にコーディネーターに通知
        // コーディネーター側で現在の状態に応じて適切に処理
        DependencyContainer.shared.appCoordinator.handleWindowClose()
        
        // フラグをリセット
        isClosingProgrammatically = false
        window = nil
    }
}
