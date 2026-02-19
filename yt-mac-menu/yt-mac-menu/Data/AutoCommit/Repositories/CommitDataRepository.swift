import Foundation

class CommitDataRepository: CommitDataRepositoryProtocol {
    private let remoteCommitDataDataSource: RemoteCommitDataDataSourceProtocol
    
    init(remoteCommitDataDataSource: RemoteCommitDataDataSourceProtocol) {
        self.remoteCommitDataDataSource = remoteCommitDataDataSource
    }
    
    func sendCommitData(_ data: CommitDataModel) async throws -> CommitSuccessModel {
        // UserDefaultsから設定を読み込む
        let shouldCreatePR = UserDefaultsManager.shared.getBool(key: .shouldCreatePR)
        var baseBranch: String? = nil
        
        // PR作成がONの場合はベースブランチが必須
        if shouldCreatePR {
            guard let branch = UserDefaultsManager.shared.get(key: .baseBranch), !branch.isEmpty else {
                throw CommitError.invalidConfiguration("ベースブランチが設定されていません。設定画面で設定してください。")
            }
            baseBranch = branch
        }
        
        let requestDTO = GitOpsRequestDTO(
            commitDataModel: data,
            baseBranch: baseBranch,
            shouldCreatePR: shouldCreatePR
        )

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

