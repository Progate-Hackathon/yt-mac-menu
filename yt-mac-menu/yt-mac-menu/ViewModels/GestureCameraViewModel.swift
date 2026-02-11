import AVFoundation
import AppKit
import SwiftUI
import Combine

class GestureCameraViewModel: ObservableObject {
    
    @Published var appState: AppStatus = .waiting {
        didSet { handleStateChange(appState) }
    }
    @Published var permissionGranted = false
    @Published var session = AVCaptureSession()
    private var monitorWindow: NSWindow?
    private let sessionQueue = DispatchQueue(label: "com.myapp.cameraSessionQueue")
    
    enum AppStatus: String {
        case waiting
        case detecting
        case success
    }
    
    init() {
        checkPermission()
    }
    
    private func handleStateChange(_ state: AppStatus) {
        print("Current State: \(state)")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch state {
            case .detecting:
                self.showWindow()
                self.startSession()
            case .success:
                self.stopSession()
                self.showWindow()
                self.scheduleAutoReset()
            case .waiting:
                self.closeWindow()
            }
        }
    }
    
    private func showWindow() {
        if monitorWindow == nil {
            createAndDisplayWindow()
        }
        monitorWindow?.makeKeyAndOrderFront(nil)
    }
    
    private func closeWindow() {
        monitorWindow?.close()
        monitorWindow = nil
    }
    
    private func createAndDisplayWindow() {
        guard let screen = NSScreen.main else { return }
        
        let windowWidth: CGFloat = 320
        let windowHeight: CGFloat = 240
        let padding: CGFloat = 16
        
        let screenRect = screen.visibleFrame
        let xPos = screenRect.maxX - windowWidth - padding
        let yPos = screenRect.maxY - windowHeight - padding
        
        let newWindow = NSWindow(
            contentRect: NSRect(x: xPos, y: yPos, width: windowWidth, height: windowHeight),
            styleMask: [.titled, .closable, .fullSizeContentView], // 枠なし
            backing: .buffered,
            defer: false
        )
        
        newWindow.titleVisibility = .hidden
        newWindow.titlebarAppearsTransparent = true
        newWindow.level = .floating
        newWindow.isReleasedWhenClosed = false
        newWindow.makeKeyAndOrderFront(nil)
        newWindow.contentView = NSHostingView(rootView: GestureCameraView(gestureCameraViewModel: self))
        
        self.monitorWindow = newWindow
    }
    
    private func scheduleAutoReset() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.appState = .waiting
        }
    }
    
    
    private func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }
    
    private func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }
    
    private func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted { self?.setupSession() }
            }
        default:
            DispatchQueue.main.async { self.permissionGranted = false }
        }
    }
    
    private func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.session.beginConfiguration()
            
            var inputAdded = false
            
            if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
               let input = try? AVCaptureDeviceInput(device: device),
               self.session.canAddInput(input) {
                self.session.addInput(input)
                inputAdded = true
            }
            
            self.session.commitConfiguration()
            DispatchQueue.main.async { self.permissionGranted = inputAdded }
        }
    }
}
