//
//  GitRepository.swift
//  yt-mac-menu
//
//  Created by cmStudent on 2026/02/15.
//

import Foundation

/// プロジェクトのGit情報（リポジトリ名、ブランチ名）を取得するRepositoryクラス
class GitRepository: GitRepositoryProtocol {
    
    
    // MARK: - Public Methods (GitRepositoryProtocol Implementation)
    
    /// リモートoriginのURLから "username/repo" 形式のリポジトリ名を取得する
    func getRepositoryName(projectPath: String) throws -> String {
        // ターミナルコマンド git config --get remote.origin.url
        let remoteURL = try getRemoteOriginURL(projectPath: projectPath)
        
        let (repoName, _) = extractRepositoryNameAndOwnerName(from: remoteURL)
        
        guard let repoName else {
            throw GitError.invalidFormat("Failed to extract repository name")
        }
        
        return repoName
    }
    
    /// 現在チェックアウトしているブランチ名を取得する
    func getCurrentBranch(projectPath: String) throws -> String {
        // ターミナルコマンド git rev-parse --abbrev-ref HEAD
        return try executeGitCommand(arguments: ["rev-parse", "--abbrev-ref", "HEAD"], at: projectPath)
    }
    
    /// Git diffを取得する
    func getDiff(projectPath: String) throws -> String {
        return try executeGitCommand(arguments: ["diff"], at: projectPath)
    }
    
    /// リポジトリのオーナー名を取得する
    func getOwner(projectPath: String) throws -> String {
        // ターミナルコマンド git config --get remote.origin.url
        let remoteURL = try getRemoteOriginURL(projectPath: projectPath)
        
        let (_, owner) = extractRepositoryNameAndOwnerName(from: remoteURL)
        
        guard let owner else {
            throw GitError.invalidFormat("Failed to extract repository name")
        }
        
        return String(owner)
    }
    
    /// 変更されたファイルのパスを取得する
    func getChangedFilePaths(projectPath: String) throws -> [String] {
        let output = try executeGitCommand(arguments: ["diff", "--name-only"], at: projectPath)
        if output.isEmpty { return [] }
        return output.split(separator: "\n").map(String.init)
    }
    
    
    func getBranches(projectPath: String) throws -> [String] {
        let output = try executeGitCommand(
            arguments: ["branch", "--format=%(refname:short)"],
            at: projectPath
        )
        
        let branches = output
            .split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        return branches
    }
    
    func fetchRemoteBranches(projectPath: String) throws {
        try executeGitCommand(arguments: ["fetch", "--all"], at: projectPath)
    }
    
    
    func getRemoteOriginURL(projectPath: String) throws -> String {
        let remote = try resolveRemoteName(projectPath: projectPath)
        return try executeGitCommand(arguments: ["config", "--get", "remote.\(remote).url"], at: projectPath)
    }

    func stashChanges(projectPath: String) throws {
        try executeGitCommand(arguments: ["stash", "push", "-m", "コミット前の変更"], at: projectPath)
    }


    // MARK: - Private Method

    /// リモート名を解決する。"origin" が存在すればそれを返し、なければ最初のリモートを返す
    private func resolveRemoteName(projectPath: String) throws -> String {
        let output = try executeGitCommand(arguments: ["remote"], at: projectPath)
        let remotes = output.split(separator: "\n").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        guard !remotes.isEmpty else {
            throw GitError.commandFailed("リモートリポジトリが設定されていません")
        }
        return remotes.contains("origin") ? "origin" : remotes[0]
    }
    
    @discardableResult
    private func executeGitCommand(arguments: [String], at path: String) throws -> String {
        let result = GitExecutor.executeSync(
            arguments: arguments,
            at: path
        )
        
        guard result.isSuccess else {
            let detail = result.stderr.isEmpty
            ? "exit code \(result.exitCode)"
            : result.stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            throw GitError.commandFailed("git \(arguments.joined(separator: " ")): \(detail)")
        }
        
        return result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// リモートURLから owner と repo を抽出する
    /// リモートURLから owner と repo を抽出する
    private func extractRepositoryNameAndOwnerName(from remoteURL: String)
    -> (repoName: String?, ownerName: String?) {
        
        var url = remoteURL.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // .git を削除
        if url.hasSuffix(".git") {
            url = String(url.dropLast(4))
        }
        
        // =========================
        // SSH形式: git@github.com:owner/repo
        // =========================
        if url.contains("@"), let colonIndex = url.lastIndex(of: ":") {
            let path = String(url[url.index(after: colonIndex)...])
            let parts = path.split(separator: "/")
            
            if parts.count == 2 {
                return (
                    repoName: String(parts[1]),
                    ownerName: String(parts[0])
                )
            }
        }
        
        // =========================
        // HTTPS形式: https://github.com/owner/repo
        // =========================
        if let urlObj = URL(string: url) {
            let components = urlObj.pathComponents
                .filter { $0 != "/" }
            
            if components.count >= 2 {
                let owner = components[components.count - 2]
                let repo = components[components.count - 1]
                
                return (
                    repoName: repo,
                    ownerName: owner
                )
            }
        }
        
        print("[GitRepository] URLからリポジトリ名を抽出できませんでした: \(remoteURL)")
        
        return (repoName: nil, ownerName: nil)
    }
}

// MARK: - GitError
enum GitError: LocalizedError {
    case commandFailed(String)
    case invalidFormat(String)
    
    var errorDescription: String? {
        switch self {
            case .commandFailed(let message):
                return "Gitコマンドエラー: \(message)"
            case .invalidFormat(let message):
                return "Git形式エラー: \(message)"
        }
    }
}
