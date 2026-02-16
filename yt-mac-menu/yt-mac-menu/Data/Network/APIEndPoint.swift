import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

protocol APIEndpoint {
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var body: Encodable? { get }
}
