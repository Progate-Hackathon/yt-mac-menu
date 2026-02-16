//
//  GitOpsAPI.swift
//  yt-mac-menu
//
//  Created by cmStudent on 2026/02/16.
//
import Foundation

struct GitOpsAPI: APIEndpoint {
    let token: String
    let requestDTO: GitOpsRequestDTO
    
    var baseURL: URL {
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
              let url = URL(string: urlString) else {
            fatalError("API_BASE_URL が Info.plist に設定されていません。")
        }
        return url
    }
    var path: String { "/github/commit_push" }
    var method: HTTPMethod { .post }
    var body: Encodable? { requestDTO }
    
    var headers: [String : String]? {
        [
            "Content-Type": "application/json",
            "X-GitHub-Token": "Bearer \(token)"
        ]
    }
}
