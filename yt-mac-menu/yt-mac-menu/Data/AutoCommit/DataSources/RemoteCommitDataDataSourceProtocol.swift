import Foundation

protocol RemoteCommitDataDataSourceProtocol {
    func performGitOps(token: String, dto: GitOpsRequestDTO) async throws -> GitOpsSuccessDTO
}
