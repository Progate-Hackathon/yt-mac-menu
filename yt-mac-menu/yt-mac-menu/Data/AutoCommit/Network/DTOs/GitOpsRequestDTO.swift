struct GitOpsRequestDTO: Encodable {
    
    
    init(commitDataModel: CommitDataModel, baseBranch: String?, shouldCreatePR: Bool){
        self.owner = commitDataModel.owner
        self.repository = commitDataModel.repository
        self.baseBranch = baseBranch
        self.headBranch = commitDataModel.headBranch
        self.createPr = shouldCreatePR
        self.files = commitDataModel.files
    }
    
    let owner: String
    let repository: String
    let baseBranch: String?
    let headBranch: String?
    let createPr: Bool?
    let files: FileChanges
}
