import AVFoundation
import Foundation
import Combine

class CameraManagementUseCase {
    @Published private(set) var cameraState: CameraState = .notAuthorized
    @Published private(set) var session = AVCaptureSession()
    
    private let sessionQueue = DispatchQueue(label: "com.ytmacmenu.cameraSessionQueue")
    
    enum CameraState {
        case notAuthorized
        case authorized
        case active
        case inactive
    }
    
    func checkPermissionStatus() -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        let isAuthorized = status == .authorized
        
        // 状態を同期
        if isAuthorized && cameraState != .authorized {
            cameraState = .authorized
        }
        
        return isAuthorized
    }
    
    func requestPermission(completion: @escaping (Bool) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            cameraState = .authorized
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.cameraState = .authorized
                        completion(true)
                    } else {
                        self?.cameraState = .notAuthorized
                        completion(false)
                    }
                }
            }
        default:
            cameraState = .notAuthorized
            completion(false)
        }
    }
    
    func setupCamera() {
        guard cameraState == .authorized else { return }
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // 既に入力がある場合はスキップ（重複追加を防ぐ）
            if !self.session.inputs.isEmpty {
                print("CameraManagementUseCase: setupCamera() - inputs already exist, skipping")
                return
            }
            
            print("CameraManagementUseCase: setupCamera() - adding camera input")
            self.session.beginConfiguration()
            
            if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
               let input = try? AVCaptureDeviceInput(device: device),
               self.session.canAddInput(input) {
                self.session.addInput(input)
                print("CameraManagementUseCase: setupCamera() - input added successfully")
            } else {
                print("CameraManagementUseCase: setupCamera() - FAILED to add input")
            }
            
            self.session.commitConfiguration()
            print("CameraManagementUseCase: setupCamera() - configuration complete")
        }
    }
    
    func startCamera() {
        guard cameraState == .authorized || cameraState == .inactive else { return }
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // セッションが既に実行中の場合はスキップ
            if self.session.isRunning {
                print("CameraManagementUseCase: startCamera() - already running")
                return
            }
            
            print("CameraManagementUseCase: startCamera() - starting session")
            self.session.startRunning()
            
            DispatchQueue.main.async {
                self.cameraState = .active
            }
        }
    }
    
    func stopCamera() {
        guard cameraState == .active else { return }
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            if self.session.isRunning {
                print("CameraManagementUseCase: stopCamera() - stopping session")
                self.session.stopRunning()
            }
            
            // セッションの入力をクリーンアップしてリセット
            print("CameraManagementUseCase: stopCamera() - removing all inputs")
            for input in self.session.inputs {
                self.session.removeInput(input)
            }
            
            DispatchQueue.main.async {
                self.cameraState = .inactive
                print("CameraManagementUseCase: stopCamera() - state set to inactive")
            }
        }
    }
}
