struct GitOpsSuccessDTO: Decodable {
    let status: String
    let params: GitOpsParamsDTO
}

struct GitOpsParamsDTO: Decodable {
    let owner: String
    let repository: String
    let baseBranch: String?
    let headBranch: String?
    let createPr: Bool?
}
