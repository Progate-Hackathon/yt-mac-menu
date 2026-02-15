import Foundation
import Combine

class AppCoordinator: ObservableObject {
    @Published private(set) var currentState: AppState = .idle
    @Published private(set) var isCameraVisible: Bool = false
    
    private let gestureRepository: GestureRepositoryProtocol
    private let commitDataModelUseCase: CommitDataModelUseCase
    private var cancellables = Set<AnyCancellable>()
    private var resetWorkItem: DispatchWorkItem?
    
    init(
        gestureRepository: GestureRepositoryProtocol,
        commitDataModelUseCase: CommitDataModelUseCase
    ) {
        self.gestureRepository = gestureRepository
        self.commitDataModelUseCase = commitDataModelUseCase
        setupBindings()
    }
    
    func start() {
        gestureRepository.connect()
    }
    
    func stop() {
        gestureRepository.disconnect()
        transition(to: .idle)
    }
    
    func handleWindowClose() {
        // ウィンドウが閉じたときの処理
        // 現在の状態に応じて適切に対応
        print("AppCoordinator: ウィンドウが閉じられました（現在の状態: \(currentState.description)）")
        
        resetWorkItem?.cancel()
        
        switch currentState {
        case .detectingHeart, .heartDetected:
            // ハート検出中または検出後の場合は、スナップ待機モードに戻る
            print("AppCoordinator: スナップ待機モードへリセット")
            isCameraVisible = false
            transition(to: .resetting)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.transition(to: .listeningForSnap)
                self?.gestureRepository.sendCommand(.disableHeart)
                self?.gestureRepository.sendCommand(.enableSnap)
            }
            
        case .resetting:
            // リセット中の場合は、既に処理が進行中なので何もしない
            print("AppCoordinator: リセット処理中のため何もしません")
            isCameraVisible = false
            
        default:
            // その他の状態では単にカメラを非表示に
            print("AppCoordinator: カメラを非表示にします")
            isCameraVisible = false
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
        transition(to: .idle)
        isCameraVisible = false
    }
    
    private func handleSnapDetected() {
        guard currentState == .listeningForSnap else {
            print("AppCoordinator: スナップ検出されましたが、状態が不正です (\(currentState.description))")
            return
        }
        
        print("AppCoordinator: スナップ検出 → ハート検出モードへ移行")
        transition(to: .snapDetected)
        
        gestureRepository.sendCommand(.disableSnap)
        gestureRepository.sendCommand(.enableHeart)
        
        isCameraVisible = true
        transition(to: .detectingHeart)
    }
    
    private func handleHeartDetected() {
        guard currentState == .detectingHeart else {
            print("AppCoordinator: ハート検出されましたが、状態が不正です (\(currentState.description))")
            return
        }
        
        print("AppCoordinator: ハート検出 → コミットデータ送信開始")
        transition(to: .heartDetected)
        
        gestureRepository.sendCommand(.disableHeart)
        
        // コミットデータの送信を開始
        sendCommitData()
    }
    
    private func sendCommitData() {
        transition(to: .committingData)
        
        Task {
            do {
                try await commitDataModelUseCase.sendCommitData()
                await MainActor.run {
                    self.handleCommitSuccess()
                }
            } catch {
                await MainActor.run {
                    self.handleCommitError(error)
                }
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
