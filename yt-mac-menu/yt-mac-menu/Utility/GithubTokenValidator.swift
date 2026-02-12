//
//  GithubTokenValidator.swift
//  yt-mac-menu
//
//  Created by アウン on 2026/02/12.
//

import Foundation

final class GithubTokenValidator {
    static var shared = GithubTokenValidator()
    
    
    private init() {}
    
    func isValidToken(_ token: String) async throws -> Bool {
        guard let url = URL(string: "https://api.github.com/user") else {
            throw GitHubTokenError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw GitHubTokenError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200:
                return true
            case 401:
                throw GitHubTokenError.invalidToken
            case 403:
                throw GitHubTokenError.forbidden
            default:
                throw GitHubTokenError.invalidResponse
            }
            
        } catch {
            throw error
        }
    }

}


enum GitHubTokenError: LocalizedError {
    case invalidToken          // 401
    case forbidden             // 403
    case invalidResponse
    case network(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidToken:
            return "GitHubトークンが無効です"
        case .forbidden:
            return "トークンの権限が不足しています"
        case .invalidResponse:
            return "不正なレスポンスを受け取りました"
        case .network(let error):
            return "ネットワークエラー: \(error.localizedDescription)"
        }
    }
}

