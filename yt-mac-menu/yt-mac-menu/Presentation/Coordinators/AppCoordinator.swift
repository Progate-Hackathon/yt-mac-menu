import Foundation
import Combine

class AppCoordinator: ObservableObject {
    @Published private(set) var currentState: AppState = .listeningForSnap
    @Published private(set) var isCameraVisible: Bool = false
    
    private let gestureRepository: GestureRepositoryProtocol
    private let sendCommitDataUseCase: SendCommitDataUseCase
    private let cameraManagementUseCase: CameraManagementUseCase
    private var cancellables = Set<AnyCancellable>()
    private var resetWorkItem: DispatchWorkItem?
    private var isRequestingCameraPermission = false
    
    init(
        gestureRepository: GestureRepositoryProtocol,
        sendCommitDataUseCase: SendCommitDataUseCase,
        cameraManagementUseCase: CameraManagementUseCase
    ) {
        self.gestureRepository = gestureRepository
        self.sendCommitDataUseCase = sendCommitDataUseCase
        self.cameraManagementUseCase = cameraManagementUseCase
        setupBindings()
    }
    
    func start() {
        // アクティブアプリの監視を開始
        KeySender.startObservingActiveApp()
        gestureRepository.connect()
    }
    
    func stop() {
        gestureRepository.disconnect()
        KeySender.stopObservingActiveApp()
        transition(to: .listeningForSnap)
    }
    
    func handleWindowClose() {
        // ウィンドウが閉じたときの処理
        print("AppCoordinator: ウィンドウが閉じられました（現在の状態: \(currentState.description)）")
        
        resetWorkItem?.cancel()
        isRequestingCameraPermission = false
        
        // まずカメラを明示的に停止（ウィンドウ破棄前に）
        print("AppCoordinator: カメラを停止します")
        cameraManagementUseCase.stopCamera()
        
        switch currentState {
        case .detectingHeart, .heartDetected, .committingData, .commitSuccess, .commitError:
            // ハート検出中、処理中、またはエラー状態から閉じる場合は、スナップ待機モードに戻る
            print("AppCoordinator: スナップ待機モードへリセット")
            
            // カメラ停止完了を待ってからウィンドウを閉じる
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.isCameraVisible = false
                self?.transition(to: .resetting)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self?.transition(to: .listeningForSnap)
                    self?.gestureRepository.sendCommand(.disableHeart)
                    self?.gestureRepository.sendCommand(.enableSnap)
                }
            }
            
        case .resetting:
            // リセット中の場合は、既に処理が進行中なので何もしない
            print("AppCoordinator: リセット処理中のため何もしません")
            isCameraVisible = false
            
        default:
            // その他の状態では単にカメラを非表示にしてスナップ待機に戻る
            print("AppCoordinator: カメラを非表示にしてスナップ待機に戻ります")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.isCameraVisible = false
                self?.transition(to: .listeningForSnap)
                self?.gestureRepository.sendCommand(.disableHeart)
                self?.gestureRepository.sendCommand(.enableSnap)
            }
        }
    }
    
    private func setupBindings() {
        gestureRepository.eventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleGestureEvent(event)
            }
            .store(in: &cancellables)
    }
    
    private func handleGestureEvent(_ event: GestureEvent) {
        switch event {
        case .connected:
            handleConnected()
        case .disconnected:
            handleDisconnected()
        case .snapDetected:
            handleSnapDetected()
        case .heartDetected:
            handleHeartDetected()
        case .handCount:
            break
        }
    }
    
    private func handleConnected() {
        print("AppCoordinator: WebSocket接続完了")
        transition(to: .listeningForSnap)
        gestureRepository.sendCommand(.enableSnap)
    }
    
    private func handleDisconnected() {
        print("AppCoordinator: WebSocket切断")
        transition(to: .listeningForSnap)
        isCameraVisible = false
    }
    
    private func handleSnapDetected() {
        guard currentState == .listeningForSnap else {
            print("AppCoordinator: スナップ検出されましたが、状態が不正です (\(currentState.description))")
            return
        }
        
        // 複数のスナップ検出を防ぐ
        if isRequestingCameraPermission {
            print("AppCoordinator: カメラ権限リクエスト中のため、スナップを無視します")
            return
        }
        
        print("AppCoordinator: スナップ検出 → カメラ権限チェック")
        transition(to: .snapDetected)
        
        gestureRepository.sendCommand(.disableSnap)
        
        // カメラ権限をチェックしてからウィンドウを開く
        checkCameraPermissionAndOpenWindow()
    }
    
    private func checkCameraPermissionAndOpenWindow() {
        // すでに権限がある場合
        if cameraManagementUseCase.checkPermissionStatus() {
            print("AppCoordinator: カメラ権限OK → カメラをセットアップしてウィンドウを開きます")
            cameraManagementUseCase.setupCamera()
            openCameraWindow()
            return
        }
        
        // 権限をリクエスト
        print("AppCoordinator: カメラ権限をリクエスト中...")
        isRequestingCameraPermission = true
        
        cameraManagementUseCase.requestPermission { [weak self] granted in
            guard let self = self else { return }
            self.isRequestingCameraPermission = false
            
            if granted {
                print("AppCoordinator: カメラ権限が許可されました → カメラをセットアップしてウィンドウを開きます")
                self.cameraManagementUseCase.setupCamera()
                self.openCameraWindow()
            } else {
                print("AppCoordinator: カメラ権限が拒否されました → スナップ待機に戻ります")
                self.transition(to: .listeningForSnap)
                self.gestureRepository.sendCommand(.enableSnap)
            }
        }
    }
    
    private func openCameraWindow() {
        // カメラセットアップが完了するまで少し待つ
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self = self else { return }
            print("AppCoordinator: ウィンドウを開いてハート検出を有効化")
            self.gestureRepository.sendCommand(.enableHeart)
            self.isCameraVisible = true
            self.transition(to: .detectingHeart)
        }
    }
    
    private func handleHeartDetected() {
        guard currentState == .detectingHeart else {
            print("AppCoordinator: ハート検出されましたが、状態が不正です (\(currentState.description))")
            return
        }
        Task {
            // アクションタイプを取得
            let actionType = UserDefaultsManager.shared.get(key: .actionType, type: ActionType.self) ?? .commit
            
            print("AppCoordinator: ハート検出 → アクション実行 (\(actionType.displayName))")
            transition(to: .heartDetected)
            gestureRepository.sendCommand(.disableHeart)
            
            // アクションタイプに応じて処理を分岐
            switch actionType {
            case .commit:
                await sendCommitData()
            case .shortcut:
                executeShortcut()
            }
        }
    }
    
    private func executeShortcut() {
        guard let hotkey = UserDefaultsManager.shared.get(key: .hotkeyConfig, type: Hotkey.self) else {
            print("AppCoordinator: ホットキーが設定されていません")
            transition(to: .shortcutSuccess)
            scheduleReset()
            return
        }

        print("AppCoordinator: ショートカット実行 - \(hotkey.displayString)")
        KeySender.activatePreviousAppAndSimulateShortcut(keyCode: hotkey.keyCode, modifiers: hotkey.modifiers)

        transition(to: .shortcutSuccess)
        scheduleReset()
    }
    
    private func sendCommitData() async {
        transition(to: .committingData)
        do {
            try await sendCommitDataUseCase.sendCommitData()
            await MainActor.run {
                self.handleCommitSuccess()
            }
        } catch {
            await MainActor.run {
                self.handleCommitError(error)
            }
        }
    }
    
    private func handleCommitSuccess() {
        print("AppCoordinator: コミット成功")
        transition(to: .commitSuccess)
        scheduleReset()
    }
    
    private func handleCommitError(_ error: Error) {
        print("AppCoordinator: コミット失敗 - \(error.localizedDescription)")
        transition(to: .commitError(error))
        // エラー時はリセットをスケジュールしない - ユーザーが手動でウィンドウを閉じる必要がある
    }
    
    private func scheduleReset() {
        resetWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            print("AppCoordinator: リセット → スナップ待機モードへ")
            
            self.transition(to: .resetting)
            self.isCameraVisible = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.transition(to: .listeningForSnap)
                self.gestureRepository.sendCommand(.enableSnap)
            }
        }
        
        resetWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: workItem)
    }
    
    private func transition(to newState: AppState) {
        let oldState = currentState
        currentState = newState
        print("AppCoordinator: 状態遷移: \(oldState.description) → \(newState.description)")
    }
}
