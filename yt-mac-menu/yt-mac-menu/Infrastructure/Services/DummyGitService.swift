//
//  GitService.swift
//  yt-mac-menu
//
//  Created by アウン on 2026/02/15.
//

import Foundation

// Issue32完成する前の仮版
class DummyGitService: GitRepositoryProtocol {
    func getRepositoryName(projectPath: String) throws -> String {
        return ""
    }
    
    func getCurrentBranch(projectPath: String) throws -> String {
        return ""
    }
    
    func getDiff(projectPath: String) throws -> String {
        return ""
    }
    
    func getOwner(projectPath: String) throws -> String {
        return ""
    }
    
    func getChangedFilePaths(projectPath: String) throws -> [String] {
        return [""]
    }
    
    
}
