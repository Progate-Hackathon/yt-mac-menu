import Foundation
import Combine

// MARK: - Gesture Countdown Model

struct GestureCountdown {
    let gestureType: GestureType
    let secondsRemaining: Double
}

// MARK: - App Coordinator

class AppCoordinator: ObservableObject {
    @Published private(set) var currentState: AppState = .idle
    @Published private(set) var isCameraVisible: Bool = false
    @Published var commandResult: ShellResult? = nil
    
    // カウントダウン状態（タイマーオーバーレイ用）
    @Published private(set) var activeCountdown: GestureCountdown?
    
    private let gestureRepository: GestureRepositoryProtocol
    private let executeActionUseCase: ExecuteGestureActionUseCase
    private let cameraManagementUseCase: CameraManagementUseCase
    private let globalHotkeyService = GlobalHotkeyService()
    private var cancellables = Set<AnyCancellable>()
    private var resetWorkItem: DispatchWorkItem?
    private var isRequestingCameraPermission = false
    private var isCalibrationMode = false
    
    // Countdown timer properties
    private var countdownTimer: Timer?
    private var currentGestureType: GestureType?
    
    init(
        gestureRepository: GestureRepositoryProtocol,
        executeActionUseCase: ExecuteGestureActionUseCase,
        cameraManagementUseCase: CameraManagementUseCase,
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

    func beginCalibration() {
        isCalibrationMode = true
    }

    func endCalibration() {
        isCalibrationMode = false
    }
    
    func handleWindowClose() {
        // ウィンドウが閉じたときの処理
        print("AppCoordinator: ウィンドウが閉じられました（現在の状態: \(currentState.description)）")
        
        cancelCountdown()
        resetWorkItem?.cancel()
        isRequestingCameraPermission = false
        commandResult = nil
        
        // まずカメラを明示的に停止（ウィンドウ破棄前に）
        print("AppCoordinator: カメラを停止します")
        cameraManagementUseCase.stopCamera()
        
        switch currentState {
            case .detectingGesture, .gestureDetected, .executingAction, .committingData, .commitSuccess, .commitError, .shortcutSuccess:
            // ジェスチャー検出中、処理中、またはエラー状態から閉じる場合は、スナップ待機モードに戻る
            print("AppCoordinator: スナップ待機モードへリセット")
            
            // カメラ停止完了を待ってからウィンドウを閉じる
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.isCameraVisible = false
                self?.transition(to: .resetting)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self?.transition(to: .listeningForSnap)
                    self?.gestureRepository.sendCommand(.disableGesture)
                    self?.gestureRepository.sendCommand(.enableSnap)
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
        case .gestureDetected(let gestureType):
            handleGestureDetected(gestureType)
        case .gestureLost(let gestureType):
            handleGestureLost(gestureType)
        case .handCount:
            break
        case .snapCalibrationProgress, .snapCalibrationCompleted:
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
        guard !isCalibrationMode else {
            print("AppCoordinator: キャリブレーションモード中のためスナップを無視します")
            return
        }
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
                print("AppCoordinator: カメラ権限が拒否されました → 権限ガイドUIを表示")
                // ウィンドウを開いて権限ガイドUIを表示（カメラはセットアップしない）
                self.openCameraWindowWithoutCamera()
            }
        }
    }
    
    private func openCameraWindowWithoutCamera() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            print("AppCoordinator: 権限なしでウィンドウを開く（ガイドUI表示）")
            self.isCameraVisible = true
            FloatingWindowController.shared.open()
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
    
    private func handleGestureDetected(_ gestureType: GestureType) {
        guard currentState == .detectingGesture else {
            print("AppCoordinator: \(gestureType.displayName)検出されましたが、状態が不正です (\(currentState.description))")
            return
        }
        
        // 同じジェスチャーのカウントダウン中は無視（連続イベント対策）
        if let current = activeCountdown, current.gestureType == gestureType {
            return
        }
        
        print("AppCoordinator: \(gestureType.displayName)検出 - カウントダウン開始（ジェスチャー検出は継続）")
        startCountdown(for: gestureType)
    }
    
    private func startCountdown(for gestureType: GestureType) {
        // Cancel any existing countdown
        cancelCountdown()
        
        currentGestureType = gestureType
        var ticks = 15  // 1.5s × 10 ticks
        // 状態遷移なし - オーバーレイで表示
        activeCountdown = GestureCountdown(gestureType: gestureType, secondsRemaining: Double(ticks) / 10.0)
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            ticks -= 1
            
            if ticks > 0 {
                self.activeCountdown = GestureCountdown(gestureType: gestureType, secondsRemaining: Double(ticks) / 10.0)
            } else {
                timer.invalidate()
                self.countdownTimer = nil
                self.activeCountdown = nil
                self.executeActionForGesture(gestureType)
            }
        }
    }
    
    private func handleGestureLost(_ gestureType: GestureType) {
        // カウントダウン中のみキャンセル
        guard activeCountdown != nil else { return }
        
        print("AppCoordinator: ジェスチャーロスト - カウントダウンをキャンセル（カメラと検出は継続）")
        cancelCountdown()
        // 状態遷移なし・カメラ継続・検出継続
    }
    
    private func cancelCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        currentGestureType = nil
        activeCountdown = nil
    }
    
    private func executeActionForGesture(_ gestureType: GestureType) {
        print("AppCoordinator: カウントダウン完了 - アクション実行開始")
        gestureRepository.sendCommand(.disableGesture)
        transition(to: .executingAction)
        
        Task {
            let summary = await executeActionUseCase.executeActions(for: gestureType)
            await handleExecutionSummary(summary)
        }
    }
    
    private func handleExecutionSummary(_ summary: ExecuteGestureActionUseCase.ExecutionSummary) async {
        await MainActor.run {
            if summary.results.isEmpty {
                print("AppCoordinator: アクションが設定されていません")
                self.transition(to: .commitError(NSError(
                    domain: "AppCoordinator",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "アクションが設定されていません"]
                )))
                return
            }
            
            let hasCommitSuccess = summary.results.contains { if case .commitSuccess = $0 { return true }; return false }
            let successState: AppState = hasCommitSuccess ? .commitSuccess : .shortcutSuccess
            
            if summary.allSucceeded {
                print("AppCoordinator: 全アクション成功 - \(summary.summaryMessage)")
                self.transition(to: successState)
                self.scheduleReset()
            } else {
                // 一部失敗でも成功があればsuccess扱いで自動リセット
                if summary.successCount > 0 {
                    print("AppCoordinator: 一部成功 - \(summary.summaryMessage)")
                    self.transition(to: successState)
                    self.scheduleReset()
                } else {
                    // 全失敗の場合のみエラー表示
                    print("AppCoordinator: 全アクション失敗")
                    if let firstError = summary.results.compactMap({ result -> Error? in
                        if case .error(let error) = result { return error }
                        return nil
                    }).first {
                        self.transition(to: .commitError(firstError))
                    }
                }
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
