struct GitOpsRequestDTO: Encodable {
    
    
    init(commitDataModel: CommitDataModel){
        self.owner = commitDataModel.owner
        self.repository = commitDataModel.repository
        self.baseBranch = nil
        self.headBranch = commitDataModel.headBranch
        self.createPr = nil
        self.files = commitDataModel.files
    }
    
    let owner: String
    let repository: String
    let baseBranch: String?
    let headBranch: String?
    let createPr: Bool?
    let files: FileChanges
}
