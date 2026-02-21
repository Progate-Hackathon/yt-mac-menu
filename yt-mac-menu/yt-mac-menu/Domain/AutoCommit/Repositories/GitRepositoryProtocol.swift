//
//  GitRepositoryProtocol.swift
//  yt-mac-menu
//
//  Created by アウン on 2026/02/14.
//  Moved to Domain layer for proper architecture
//

import Foundation

protocol GitRepositoryProtocol {
    func getRepositoryName(projectPath: String) throws -> String
    func getRemoteOriginURL(projectPath: String) throws -> String
    func getBranches(projectPath: String) throws -> [String]
    func fetchRemoteBranches(projectPath: String) throws
    func getCurrentBranch(projectPath: String) throws -> String
    func getDiff(projectPath: String) throws -> String
    func getOwner(projectPath: String) throws -> String
    func getChangedFilePaths(projectPath: String) throws -> [String]
}
