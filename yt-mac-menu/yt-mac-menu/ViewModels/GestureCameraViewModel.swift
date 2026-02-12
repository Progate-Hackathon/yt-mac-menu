import AVFoundation
import SwiftUI
import Combine

class GestureCameraViewModel: ObservableObject {
    @Published var appState: AppStatus = .waiting {
        didSet { handleStateChange(appState) }
    }
    @Published var handCount: Int = 0
    @Published var session = AVCaptureSession()
    @Published var isConnected: Bool = false

    // ロジック担当のServiceを持つ
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


    // Serviceからの通知を監視してUI状態を更新する
    private func setupBindings() {
        service.eventSubject
            .receive(on: DispatchQueue.main) 
            .sink { [weak self] event in
                guard let self = self else { return }

                switch event {
                case .heartDetected:
                    if self.appState == .detecting {
                        self.appState = .success
                    }

                case .handCount(let count):
                    self.handCount = count

                case .connected:
                    self.isConnected = true

                case .disconnected:
                    self.isConnected = false

                case .snapDetected:
                    print("指パッチン！")
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
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch state {
            case .detecting:
                self.startSession()
                self.service.sendCommand("enable_heart")
            case .success:
                self.service.sendCommand("disable_heart")
                self.stopSession()
                self.scheduleAutoReset()
            case .waiting:
                self.service.sendCommand("disable_heart")
                self.handCount = 0
                self.stopSession()
            case .unauthorized:
                self.stopSession()
            }
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
