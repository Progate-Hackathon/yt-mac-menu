import Foundation

class DependencyContainer {
    static let shared = DependencyContainer()
    
    private init() {}
    
    // MARK: - Data Layer
    
    private lazy var commitDataRepository: CommitDataRepositoryProtocol = {
        return CommitDataRepository()
    }()
    
    private lazy var webSocketClient: WebSocketClientProtocol = {
        let url = URL(string: "ws://localhost:8765")!
        return WebSocketClient(url: url)
    }()
    
    private lazy var remoteGestureDataSource: RemoteGestureDataSource = {
        return RemoteGestureDataSource(webSocketClient: webSocketClient)
    }()
    
    private lazy var fileReaderRepository: FileReaderRepository = {
        return FileReaderRepository()
    }()
    
    
    private lazy var gestureRepository: GestureRepositoryProtocol = {
        return GestureRepository(
            webSocketClient: webSocketClient,
            remoteDataSource: remoteGestureDataSource
        )
    }()
    
    private lazy var gitRepository: GitRepositoryProtocol = {
        return DummyGitService()
    }()
    
    // MARK: - Domain Layer
    
    func makeGestureDetectionUseCase() -> GestureDetectionUseCase {
        return GestureDetectionUseCase(gestureRepository: gestureRepository)
    }
    
    func makeCameraManagementUseCase() -> CameraManagementUseCase {
        return CameraManagementUseCase()
    }
    
    func makeCommitDataModelUseCase() -> CommitDataModelUseCase {
        return CommitDataModelUseCase(commitDataRepository: commitDataRepository, fileReader: fileReaderRepository, gitRepository: gitRepository)
    }
    
    // MARK: - Presentation Layer
    
    private(set) lazy var appCoordinator: AppCoordinator = {
        return AppCoordinator(
            gestureRepository: gestureRepository,
            commitDataModelUseCase: makeCommitDataModelUseCase()
        )
    }()
    
    func makeAppCoordinator() -> AppCoordinator {
        return appCoordinator
    }
}
