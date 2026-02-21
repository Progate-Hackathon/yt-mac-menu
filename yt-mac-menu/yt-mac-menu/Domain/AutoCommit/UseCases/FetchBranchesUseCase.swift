//
//  FetchBranchesUseCase.swift
//  yt-mac-menu
//
//  Created by アウン on 2026/02/21.
//

import Foundation

class FetchBranchesUseCase {
    private let gitRepository: GitRepository
    
    init(gitRepository: GitRepository) {
        self.gitRepository = gitRepository
    }
    
    
    func getBranches() throws -> [String] {
        guard let projectPath = UserDefaultsManager.shared.get(key: .projectFolderPath, type: String.self) else {
            print("CommitDataModelUseCase: Project Pathが見つかりません。")
            throw FetchBranchesUseCaseError.projectPathNotFound
        }
        
        // リモートURLが設定されているかをチェックするだけ
        guard let _ = try?  gitRepository.getRemoteOriginURL(projectPath: projectPath) else {
            print("リモートURLが見つかりません。")
            throw FetchBranchesUseCaseError.remoteURLNotFound
        }
        
        
        return try gitRepository.getBranches(projectPath: projectPath)
    }
}


enum FetchBranchesUseCaseError: LocalizedError {
    case projectPathNotFound
    case remoteURLNotFound
    
    var errorDescription: String? {
        switch self {
        case .projectPathNotFound:
            return "Projectファイルのパスが見つかりません。"
            
        case .remoteURLNotFound:
            return "リモートURLが見つかりません。"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .projectPathNotFound:
            return "設定画面から正しいProjectフォルダのパスを選択してください。"
            
        case .remoteURLNotFound:
            return "GitHubのリモートURLが設定されているか確認してください（git remote -v）。"
        }
    }
}
