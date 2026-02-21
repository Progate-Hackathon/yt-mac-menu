import Foundation
import Combine

class AppCoordinator: ObservableObject {
    @Published private(set) var currentState: AppState = .idle
    @Published private(set) var isCameraVisible: Bool = false
    @Published var commandResult: ShellResult? = nil
    
    private let gestureRepository: GestureRepositoryProtocol
    private let executeActionUseCase: ExecuteGestureActionUseCase
    private let cameraManagementUseCase: CameraManagementUseCase
    private let globalHotkeyService = GlobalHotkeyService()
    private var cancellables = Set<AnyCancellable>()
    private var resetWorkItem: DispatchWorkItem?
    private var isRequestingCameraPermission = false
    
    init(
        gestureRepository: GestureRepositoryProtocol,
        executeActionUseCase: ExecuteGestureActionUseCase,
        cameraManagementUseCase: CameraManagementUseCase
    ) {
        self.gestureRepository = gestureRepository
        self.executeActionUseCase = executeActionUseCase
        self.cameraManagementUseCase = cameraManagementUseCase
        setupBindings()
    }
    
    func start() {
        // アクティブアプリの監視を開始
        KeySender.startObservingActiveApp()
        // グローバルショートカット監視を開始
        globalHotkeyService.onTrigger = { [weak self] in
            self?.handleSnapTriggerShortcut()
        }
        globalHotkeyService.start()
        gestureRepository.connect()
    }
    
    func stop() {
        gestureRepository.disconnect()
        globalHotkeyService.stop()
        KeySender.stopObservingActiveApp()
        transition(to: .idle)
    }
    
    func handleWindowClose() {
        // ウィンドウが閉じたときの処理
        print("AppCoordinator: ウィンドウが閉じられました（現在の状態: \(currentState.description)）")
        
        resetWorkItem?.cancel()
        isRequestingCameraPermission = false
        commandResult = nil
        
        // まずカメラを明示的に停止（ウィンドウ破棄前に）
        print("AppCoordinator: カメラを停止します")
        cameraManagementUseCase.stopCamera()
        
        switch currentState {
            case .detectingGesture, .thumbsUpDetected, .peaceDetected, .heartDetected, .committingData, .commitSuccess, .commitError, .shortcutSuccess:
            // ハート検出中、処理中、またはエラー状態から閉じる場合は、スナップ待機モードに戻る
            print("AppCoordinator: スナップ待機モードへリセット")
            
            // カメラ停止完了を待ってからウィンドウを閉じる
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.isCameraVisible = false
                self?.transition(to: .resetting)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self?.transition(to: .idle)
                    self?.gestureRepository.sendCommand(.disableGesture)
                }
            }
            
        case .resetting:
            // リセット中の場合は、既に処理が進行中なので何もしない
            print("AppCoordinator: リセット処理中のため何もしません")
            isCameraVisible = false
            
        case .idle:
            // snap検知はOFF状態なので何もしない
            print("AppCoordinator: idle状態のためウィンドウクローズを無視")
            isCameraVisible = false

        case .listeningForSnap:
            // snap検知ON状態を維持して再開
            print("AppCoordinator: カメラを非表示にしてスナップ待機に戻ります")
            isCameraVisible = false

            case .snapDetected:
            // スナップ検出直後（カメラ未起動）に閉じた場合はsnap検知を再開する
            print("AppCoordinator: snapDetected中に閉じられました → snap検知を再開")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.isCameraVisible = false
                self?.transition(to: .listeningForSnap)
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
        case .audioDetected(.snap):
            handleSnapDetected()
        case .gestureDetected(.heart):
            handleHeartDetected()
        case .gestureDetected(.thumbsUp):
            handleThumbsUpDetected()
        case .gestureDetected(.peace):
            handlePeaceDetected()
        case .handCount:
            break
        }
    }
    
    private func handleConnected() {
        print("AppCoordinator: WebSocket接続完了 → ショートカット待機中")
        transition(to: .idle)
    }
    
    private func handleDisconnected() {
        print("AppCoordinator: WebSocket切断")
        if currentState == .listeningForSnap {
            gestureRepository.sendCommand(.disableSnap)
        }
        transition(to: .idle)
        isCameraVisible = false
    }
    
    private func handleSnapTriggerShortcut() {
        switch currentState {
        case .idle:
            // snap検知をONにする
            print("AppCoordinator: snap検知トリガーショートカット → enableSnap（ON）")
            transition(to: .listeningForSnap)
            gestureRepository.sendCommand(.enableSnap)
        case .listeningForSnap:
            // snap検知をOFFにする
            print("AppCoordinator: snap検知トリガーショートカット → disableSnap（OFF）")
            gestureRepository.sendCommand(.disableSnap)
            transition(to: .idle)
        default:
            // snap検知サイクル中（snapDetected〜resetting）は無視
            print("AppCoordinator: snap検知サイクル中のためトグルを無視 (\(currentState.description))")
        }
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
                print("AppCoordinator: カメラ権限が拒否されました → ショートカット待機に戻ります")
                self.transition(to: .idle)
            }
        }
    }
    
    private func openCameraWindow() {
        // カメラセットアップが完了するまで少し待つ
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self = self else { return }
            print("AppCoordinator: ウィンドウを開いてハート検出を有効化")
            self.gestureRepository.sendCommand(.enableGesture)
            self.isCameraVisible = true
            self.transition(to: .detectingGesture)
        }
    }
    
    private func handleHeartDetected() {
        guard currentState == .detectingGesture else {
            print("AppCoordinator: ハート検出されましたが、状態が不正です (\(currentState.description))")
            return
        }
        
        print("AppCoordinator: ハート検出")
        gestureRepository.sendCommand(.disableGesture)
        transition(to: .heartDetected)
        
        Task {
            let config = ExecuteGestureActionUseCase.ActionConfig(
                hotkeyKey: .hotkeyConfig,
                commandKey: .commandString,
                actionTypeKey: .actionType
            )
            let result = await executeActionUseCase.executeAction(config: config)
            await handleActionResult(result)
        }
    }
    
    private func handleThumbsUpDetected() {
        guard currentState == .detectingGesture else {
            print("AppCoordinator: サムズアップ検出されましたが、状態が不正です (\(currentState.description))")
            return
        }
        
        print("AppCoordinator: サムズアップ検出")
        gestureRepository.sendCommand(.disableGesture)
        transition(to: .thumbsUpDetected)
        
        Task {
            let config = ExecuteGestureActionUseCase.ActionConfig(
                hotkeyKey: .thumbsUpHotkeyConfig,
                commandKey: .thumbsUpCommandString,
                actionTypeKey: .thumbsUpActionType
            )
            let result = await executeActionUseCase.executeAction(config: config)
            await handleActionResult(result)
        }
    }
    
    private func handlePeaceDetected() {
        guard currentState == .detectingGesture else {
            print("AppCoordinator: ピース検出されましたが、状態が不正です (\(currentState.description))")
            return
        }
        
        print("AppCoordinator: ピース検出")
        gestureRepository.sendCommand(.disableGesture)
        transition(to: .peaceDetected)
        
        Task {
            let config = ExecuteGestureActionUseCase.ActionConfig(
                hotkeyKey: .peaceHotkeyConfig,
                commandKey: .peaceCommandString,
                actionTypeKey: .peaceActionType
            )
            let result = await executeActionUseCase.executeAction(config: config)
            await handleActionResult(result)
        }
    }
    
    private func handleActionResult(_ result: ExecuteGestureActionUseCase.ActionResult) async {
        await MainActor.run {
            switch result {
            case .commitSuccess:
                print("AppCoordinator: コミット成功")
                self.transition(to: .commitSuccess)
                self.scheduleReset()
                
            case .shortcutSuccess:
                print("AppCoordinator: ショートカット成功")
                self.transition(to: .shortcutSuccess)
                self.scheduleReset()
                
            case .commandSuccess(let shellResult):
                print("AppCoordinator: コマンド成功")
                self.commandResult = shellResult
                self.transition(to: .commitSuccess)
                self.scheduleReset()
                
            case .error(let error):
                print("AppCoordinator: アクション失敗 - \(error.localizedDescription)")
                self.transition(to: .commitError(error))
                // エラー時はリセットをスケジュールしない - ユーザーが手動でウィンドウを閉じる必要がある
            }
        }
    }
    
    private func scheduleReset() {
        resetWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            print("AppCoordinator: リセット → スナップ待機モードへ")
            
            self.transition(to: .resetting)
            self.isCameraVisible = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.transition(to: .idle)
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
