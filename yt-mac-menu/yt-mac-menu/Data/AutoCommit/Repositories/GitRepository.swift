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
        guard let branch = executeGitCommand(arguments: ["rev-parse", "--abbrev-ref", "HEAD"], at: projectPath) else {
            throw GitError.commandFailed("Failed to get current branch")
        }
        return branch
    }
    
    /// Git diffを取得する
    func getDiff(projectPath: String) throws -> String {
        guard let diff = executeGitCommand(arguments: ["diff"], at: projectPath) else {
            throw GitError.commandFailed("Failed to get diff")
        }
        return diff
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
        guard let output = executeGitCommand(arguments: ["diff", "--name-only"], at: projectPath) else {
            throw GitError.commandFailed("Failed to get changed file paths")
        }
        return output.split(separator: "\n").map(String.init)
    }
    
    
    func getBranches(projectPath: String) throws -> [String] {
        guard let output = executeGitCommand(
            arguments: ["branch", "--format=%(refname:short)"],
            at: projectPath
        ) else {
            throw GitError.commandFailed("結果の取得に失敗")
        }

        let branches = output
            .split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        return branches
    }

    func fetchRemoteBranches(projectPath: String) throws {
        guard let _ = executeGitCommand(
            arguments: ["fetch", "--all"],
            at: projectPath
        ) else {
            throw GitError.commandFailed("リモートブランチの取得に失敗")
        }
    }
    
    
    func getRemoteOriginURL(projectPath: String) throws -> String {
        guard let remoteURL = executeGitCommand(arguments: ["config", "--get", "remote.origin.url"], at: projectPath) else {
            throw GitError.commandFailed("Failed to get remote URL")
        }
        return remoteURL
    }

    // MARK: - Private Method
    
    private func executeGitCommand(arguments: [String], at path: String) -> String? {
        let process = Process()
        process.currentDirectoryURL = URL(fileURLWithPath: path)
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = arguments

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        do {
            try process.run()
            process.waitUntilExit()

            // プロセス終了後に同期的に読み取る
            let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
            let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

            let stderrString = String(data: stderrData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard process.terminationStatus == 0 else {
                if let stderrString, !stderrString.isEmpty {
                    print("[GitRepository] Gitコマンドが終了コードで失敗しました \(process.terminationStatus): git \(arguments.joined(separator: " ")), stderr: \(stderrString)")
                } else {
                    print("[GitRepository] Gitコマンドが終了コードで失敗しました \(process.terminationStatus): git \(arguments.joined(separator: " "))")
                }
                return nil
            }

            let stdoutString = String(data: stdoutData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return stdoutString
        } catch {
            print("[GitRepository] Gitコマンドエラー: \(error.localizedDescription) — git \(arguments.joined(separator: " "))")
            return nil
        }
    }

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
