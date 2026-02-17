struct GitOpsErrorDTO: Error, Decodable {
    let message: String
    let details: GitOpsErrorDetails?
}

struct GitOpsErrorDetails: Decodable {
    let status: Int
    let upstreamStatus: Int?
    let upstreamMessage: String?
    let context: [String: String]?
}
