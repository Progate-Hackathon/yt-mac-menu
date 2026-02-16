import Foundation

final class RemoteCommitDataDataSource: RemoteCommitDataDataSourceProtocol {
    private let apiClient: APIClientProtocol
    
    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }
    
    func performGitOps(token: String, dto: GitOpsRequestDTO) async throws -> GitOpsSuccessDTO {

        let endpoint = GitOpsAPI(token: token, requestDTO: dto)
        
        do {
            return try await apiClient.send(endpoint)
        } catch APIError.httpError(_, let data) {
            if let errorResponse = try? JSONDecoder().decode(GitOpsErrorDTO.self, from: data) {
                throw errorResponse
            }
            throw APIError.invalidResponse
        } catch {
            throw error
        }
    }
}
