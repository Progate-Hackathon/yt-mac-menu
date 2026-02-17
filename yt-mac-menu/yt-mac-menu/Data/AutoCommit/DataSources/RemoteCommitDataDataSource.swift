import Foundation

final class RemoteCommitDataDataSource: RemoteCommitDataDataSourceProtocol {
    
    func send(token: String, dto: GitOpsRequestDTO) async throws -> GitOpsSuccessDTO {
        
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String else {
            throw CommitError.invalidConfiguration("API_BASE_URL が Info.plist に見つかりません")
        }
        
        guard let baseURL = URL(string: urlString) else {
            throw CommitError.invalidConfiguration("API_BASE_URL の形式が不正です: \(urlString)")
        }
        
        let url = baseURL.appendingPathComponent("/github/commit_push")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "X-GitHub-Token")
        
        do {
            request.httpBody = try JSONEncoder().encode(dto)
        } catch {
            throw CommitError.requestCreationError(error)
        }
        
        let data: Data
        let response: URLResponse
        
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw CommitError.networkError(error)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CommitError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorRes = try? JSONDecoder().decode(GitOpsErrorDTO.self, from: data)
            
            throw CommitError.serverError(
                message: errorRes?.message ?? "不明なサーバーエラー",
                status: httpResponse.statusCode,
                upstreamMessage: errorRes?.details?.upstreamMessage
            )
        }
        
        do {
            return try JSONDecoder().decode(GitOpsSuccessDTO.self, from: data)
        } catch {
            throw CommitError.decodingError(error)
        }
    }
}
