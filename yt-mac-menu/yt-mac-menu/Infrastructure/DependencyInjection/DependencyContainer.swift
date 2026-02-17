import Foundation

class DependencyContainer {
    static let shared = DependencyContainer()
    
    private init() {}
    
    // MARK: - Data Layer
    
    private lazy var remoteCommitDataDataSource: RemoteCommitDataDataSourceProtocol = {
        return RemoteCommitDataDataSource()
    }()
    
    private lazy var commitDataRepository: CommitDataRepositoryProtocol = {
        return CommitDataRepository(remoteCommitDataDataSource: remoteCommitDataDataSource)
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
        return DummyGitRepository()
    }()
    
    // MARK: - Domain Layer
    
    private lazy var cameraManagementUseCase: CameraManagementUseCase = {
        return CameraManagementUseCase()
    }()
    
    func makeGestureDetectionUseCase() -> GestureDetectionUseCase {
        return GestureDetectionUseCase(gestureRepository: gestureRepository)
    }
    
    func makeCameraManagementUseCase() -> CameraManagementUseCase {
        return cameraManagementUseCase
    }
    
    func makeCommitDataModelUseCase() -> CommitDataModelUseCase {
        return CommitDataModelUseCase(commitDataRepository: commitDataRepository, fileReader: fileReaderRepository, gitRepository: gitRepository)
    }
    
    // MARK: - Presentation Layer
    
    private(set) lazy var appCoordinator: AppCoordinator = {
        return AppCoordinator(
            gestureRepository: gestureRepository,
            commitDataModelUseCase: makeCommitDataModelUseCase(),
            cameraManagementUseCase: makeCameraManagementUseCase()
        )
    }()
    
    func makeAppCoordinator() -> AppCoordinator {
        return appCoordinator
    }
}
