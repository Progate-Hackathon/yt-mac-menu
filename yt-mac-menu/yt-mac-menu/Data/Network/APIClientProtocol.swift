import Foundation

protocol APIClientProtocol {
    func send<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T
}

enum APIError: Error {
    case invalidResponse
    case httpError(statusCode: Int, data: Data)
    case decodingError(Error)
    case unknown(Error)
}
