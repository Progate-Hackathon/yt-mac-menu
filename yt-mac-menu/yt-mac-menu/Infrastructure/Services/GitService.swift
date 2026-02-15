//
//  GitService.swift
//  yt-mac-menu
//
//  Created by cmStudent on 2026/02/15.
//

import Foundation

/// プロジェクトのGit情報（リポジトリ名、ブランチ名）を取得するサービスクラス
class GitService {

    // MARK: - Public Method
    
    /// リモートoriginのURLから "username/repo" 形式のリポジトリ名を取得する
    func getRepositoryName(projectPath: String) -> String? {
        // ターミナルコマンド git config --get remote.origin.url
        guard let remoteURL = executeGitCommand(arguments: ["config", "--get", "remote.origin.url"], at: projectPath) else {
            return nil
        }
        return extractRepositoryName(from: remoteURL)
    }

    /// 現在チェックアウトしているブランチ名を取得する
    func getCurrentBranch(projectPath: String) -> String? {
        // ターミナルコマンド git rev-parse --abbrev-ref HEAD
        return executeGitCommand(arguments: ["rev-parse", "--abbrev-ref", "HEAD"], at: projectPath)
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

        // プロセス実行中に標準出力・標準エラー出力を読み取る
        var stdoutData = Data()
        var stderrData = Data()
        let readGroup = DispatchGroup()

        readGroup.enter()
        DispatchQueue.global().async {
            let data = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
            stdoutData.append(data)
            readGroup.leave()
        }

        readGroup.enter()
        DispatchQueue.global().async {
            let data = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            stderrData.append(data)
            readGroup.leave()
        }

        do {
            try process.run()
            process.waitUntilExit()

            // 読み取りスレッドの完了を待機
            readGroup.wait()

            let stderrString = String(data: stderrData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard process.terminationStatus == 0 else {
                if let stderrString, !stderrString.isEmpty {
                    print("[GitService] Gitコマンドが終了コードで失敗しました \(process.terminationStatus): git \(arguments.joined(separator: " ")), stderr: \(stderrString)")
                } else {
                    print("[GitService] Gitコマンドが終了コードで失敗しました \(process.terminationStatus): git \(arguments.joined(separator: " "))")
                }
                return nil
            }

            let stdoutString = String(data: stdoutData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return stdoutString
        } catch {
            let stderrString = String(data: stderrData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if stderrString.isEmpty {
                print("[GitService] Gitコマンドエラー: \(error.localizedDescription) — git \(arguments.joined(separator: " "))")
            } else {
                print("[GitService] Gitコマンドエラー: \(error.localizedDescription) — git \(arguments.joined(separator: " ")), stderr: \(stderrString)")
            }
            return nil
        }
    }

    /// リモートURLから "username/repo" 形式のリポジトリ名を抽出する
    private func extractRepositoryName(from remoteURL: String) -> String? {
        var url = remoteURL

        if url.hasSuffix(".git") {
            url = String(url.dropLast(4))
        }

        // SSH形式: git@github.com:username/repo
        if url.contains("@") && url.contains(":") {
            if let colonIndex = url.lastIndex(of: ":") {
                let path = String(url[url.index(after: colonIndex)...])
                return path.isEmpty ? nil : path
            }
        }

        // HTTPS形式: https://github.com/username/repo
        if let urlObj = URL(string: url) {
            let components = urlObj.pathComponents.filter { $0 != "/" }
            if components.count >= 2 {
                let owner = components[components.count - 2]
                let repo = components[components.count - 1]
                return "\(owner)/\(repo)"
            }
        }

        print("[GitService] URLからリポジトリ名を抽出できませんでした: \(remoteURL)")
        return nil
    }
}
