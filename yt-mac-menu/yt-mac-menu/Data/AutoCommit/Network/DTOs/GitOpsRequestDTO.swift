struct GitOpsRequestDTO: Encodable {
    let owner: String
    let repository: String
    let baseBranch: String?
    let headBranch: String?
    let createPr: Bool?
    let files: [String: FileAction]
}

enum FileAction: Encodable {
    case update(String)
    case delete
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .update(let content): try container.encode(content)
        case .delete: try container.encodeNil()
        }
    }
}
