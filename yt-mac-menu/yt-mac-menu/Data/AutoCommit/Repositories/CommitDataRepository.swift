import Foundation

class CommitDataRepository: CommitDataRepositoryProtocol {
    private let remoteCommitDataDataSource: RemoteCommitDataDataSourceProtocol
    
    init(remoteCommitDataDataSource: RemoteCommitDataDataSourceProtocol) {
        self.remoteCommitDataDataSource = remoteCommitDataDataSource
    }
    
    func sendCommitData(_ data: CommitDataModel) async throws -> CommitSuccessModel {
        let requestDTO = GitOpsRequestDTO(commitDataModel: data)
        let successDTO = try await remoteCommitDataDataSource.send(token: data.githubToken, dto: requestDTO)
        let urlString = "https://github.com/\(successDTO.params.owner)/\(successDTO.params.repository)"
        
        guard let repositoryURL = URL(string: urlString) else {
            throw CommitError.decodingError(URLError(.badURL))
        }
        
        return CommitSuccessModel(
            repositoryURL: repositoryURL,
            status: successDTO.status
        )
    }
}

