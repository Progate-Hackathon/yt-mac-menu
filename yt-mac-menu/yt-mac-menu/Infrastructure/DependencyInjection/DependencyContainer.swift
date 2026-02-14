import Foundation

class DependencyContainer {
    static let shared = DependencyContainer()
    
    private init() {}
    
    // MARK: - Data Layer
    
    private lazy var webSocketClient: WebSocketClientProtocol = {
        let url = URL(string: "ws://localhost:8765")!
        return WebSocketClient(url: url)
    }()
    
    private lazy var remoteGestureDataSource: RemoteGestureDataSource = {
        return RemoteGestureDataSource(webSocketClient: webSocketClient)
    }()
    
    private lazy var gestureRepository: GestureRepositoryProtocol = {
        return GestureRepository(
            webSocketClient: webSocketClient,
            remoteDataSource: remoteGestureDataSource
        )
    }()
    
    // MARK: - Domain Layer
    
    func makeGestureDetectionUseCase() -> GestureDetectionUseCase {
        return GestureDetectionUseCase(gestureRepository: gestureRepository)
    }
    
    func makeCameraManagementUseCase() -> CameraManagementUseCase {
        return CameraManagementUseCase()
    }
    
    // MARK: - Presentation Layer
    
    func makeAppCoordinator() -> AppCoordinator {
        return AppCoordinator(gestureRepository: gestureRepository)
    }
}
