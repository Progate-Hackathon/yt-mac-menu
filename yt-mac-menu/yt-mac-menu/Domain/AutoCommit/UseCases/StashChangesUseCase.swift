//
//  StashChangesUseCase.swift
//  yt-mac-menu
//
//  Created by アウン on 2026/02/22.
//

import Foundation

class StashChangesUseCase {
    private let gitRepository: GitRepositoryProtocol
    
    init(gitRepository: GitRepositoryProtocol) {
        self.gitRepository = gitRepository
    }
    
    
    func stashChanges() throws {
        guard let projectPath = UserDefaultsManager.shared.get(key: .projectFolderPath, type: String.self) else {
            throw StashChangesUseCaseError.projectPathNotFound
        }
        try gitRepository.stashChanges(projectPath: projectPath)
    }

    func pullChanges() throws {
        guard let projectPath = UserDefaultsManager.shared.get(key: .projectFolderPath, type: String.self) else {
            throw StashChangesUseCaseError.projectPathNotFound
        }
        try gitRepository.pull(projectPath: projectPath)
    }
}


enum StashChangesUseCaseError: LocalizedError {
    case projectPathNotFound
    
    var errorDescription: String? {
        switch self {
            case .projectPathNotFound:
                return "プロジェクトのパスが設定されていません。設定画面からパスを設定してください。"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
            case .projectPathNotFound:
                return "設定画面でプロジェクトのパスを設定してから再試行してください。"
        }
    }
}
