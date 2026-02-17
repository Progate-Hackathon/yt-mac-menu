import Foundation

protocol RemoteCommitDataDataSourceProtocol {
    func send(token: String, dto: GitOpsRequestDTO) async throws -> GitOpsSuccessDTO
}
