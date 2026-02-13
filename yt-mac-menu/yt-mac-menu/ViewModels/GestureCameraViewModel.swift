import AVFoundation
import SwiftUI
import Combine

class GestureCameraViewModel: ObservableObject {
    @Published var appState: AppStatus = .waiting {
        didSet { handleStateChange(appState) }
    }
    @Published var handCount: Int = 0
    @Published var session = AVCaptureSession()
    
    private let service = GestureService.shared
    private var cancellables = Set<AnyCancellable>()
    private let sessionQueue = DispatchQueue(label: "com.myapp.cameraSessionQueue")
    
    enum AppStatus: String {
        case waiting
        case detecting
        case success
        case unauthorized
    }
    
    init() {
        print("GestureCameraViewModel initialized")
        checkPermission()
        setupBindings()
    }
    
    private func setupBindings() {
        service.eventSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self = self else { return }
                switch event {
                case .connected:
                    self.service.sendCommand("enable_heart")
                case .heartDetected:
                    self.service.sendCommand("disable_heart")
                    self.service.sendCommand("enable_snap")
                    self.appState = .success
                    
                case .handCount(let count):
                    self.handCount = count
                    
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }
    
    private func scheduleAutoReset() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.appState = .waiting
        }
    }
    
    private func handleStateChange(_ state: AppStatus) {
        switch state {
        case .detecting:
            self.startSession()
        case .success:
            self.stopSession()
            self.scheduleAutoReset()
        case .waiting:
            self.handCount = 0
        case .unauthorized:
            break
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
                if granted {
                    self?.setupSession()
                } else {
                    DispatchQueue.main.async {
                        self?.appState = .unauthorized
                    }
                }
            }
        default:
            DispatchQueue.main.async {
                self.appState = .unauthorized
            }
        }
    }
    
    private func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            if !self.session.inputs.isEmpty {
                DispatchQueue.main.async { self.appState = .detecting }
                return
            }
            
            self.session.beginConfiguration()
            
            var isSuccess = false
            
            if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
               let input = try? AVCaptureDeviceInput(device: device),
               self.session.canAddInput(input) {
                
                self.session.addInput(input)
                isSuccess = true
            }
            
            self.session.commitConfiguration()
            
            DispatchQueue.main.async {
                if isSuccess {
                    self.appState = .detecting
                } else {
                    self.appState = .unauthorized
                }
            }
        }
    }
}
