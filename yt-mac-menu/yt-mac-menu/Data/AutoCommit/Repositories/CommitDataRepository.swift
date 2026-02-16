import Foundation
import Combine

class CommitDataRepository: CommitDataRepositoryProtocol {
    private let remoteCommitDataDataSource: RemoteCommitDataDataSourceProtocol
    
    init(
        remoteCommitDataDataSource: RemoteCommitDataDataSourceProtocol
    ) {
        self.remoteCommitDataDataSource = remoteCommitDataDataSource
    }
    
    func sendCommitData(_ data: CommitDataModel) async throws -> CommitSuccessModel {
        let requestDTO = GitOpsRequestDTO(
            owner: data.owner,
            repository: data.repository,
            baseBranch: nil,
            headBranch: data.headBranch,
            createPr: nil,
            files: data.files.mapValues { content in
                if let content = content {
                    return .update(content)
                } else {
                    return .delete
                }
            }
        )
        
        do {
            let successDTO = try await remoteCommitDataDataSource.performGitOps(token: data.githubToken, dto: requestDTO)
            
            let urlString = "https://github.com/\(successDTO.params.owner)/\(successDTO.params.repository)"
            
            guard let repositoryURL = URL(string: urlString) else {
                throw CommitError.networkError(URLError(.badURL))
            }
            
            return CommitSuccessModel(
                repositoryURL: repositoryURL,
                status: successDTO.status
            )
            
        } catch let dtoError as GitOpsErrorDTO {
            throw CommitError.remoteError(
                message: dtoError.message,
                detail: dtoError.details?.context?.values.joined(separator: ", ")
            )
            
        } catch {
            throw CommitError.networkError(error)
        }
    }
}
