import Foundation
import Combine

class CommitDataRepository: CommitDataRepositoryProtocol {
    private let RemoteCommitDataDataSource: RemoteCommitDataDataSourceProtocol
    
    init(
        remoteCommitDataDataSource: RemoteCommitDataDataSourceProtocol
    ) {
        self.RemoteCommitDataDataSource = remoteCommitDataDataSource
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
            let successDTO = try await RemoteCommitDataDataSource.performGitOps(token: data.githubToken, dto: requestDTO)
            
            let urlString = "https://github.com/\(successDTO.params.owner)/\(successDTO.params.repository)"
            
            return CommitSuccessModel(
                repositoryURL: URL(string: urlString)!,
                status: successDTO.status
            )
            
        } catch let dtoError as GitOpsErrorDTO {
            throw CommitError.remoteError(
                message: dtoError.message,
                detail: dtoError.details?.context?.description
            )
            
        } catch {
            throw CommitError.networkError(error)
        }
    }
}
