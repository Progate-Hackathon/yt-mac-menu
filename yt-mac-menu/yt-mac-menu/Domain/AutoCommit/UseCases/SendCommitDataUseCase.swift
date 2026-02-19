//
//  CommitDataModelUseCase.swift
//  yt-mac-menu
//
//  Created by アウン on 2026/02/14.
//

import Foundation

class SendCommitDataUseCase {
    private let commitDataRepository: CommitDataRepositoryProtocol
    private let fileReader: FileReaderRepositoryProtocol
    private let gitRepository: GitRepositoryProtocol
    
    init(
        commitDataRepository: CommitDataRepositoryProtocol,
        fileReader: FileReaderRepositoryProtocol,
        gitRepository: GitRepositoryProtocol
    ) {
        self.commitDataRepository = commitDataRepository
        self.fileReader = fileReader
        self.gitRepository = gitRepository
    }
    
    
    func sendCommitData() async throws -> CommitSuccessModel {
        let model = try createCommitDataModel()
        
        // TODO: CommitDataRepositoryで送信のロジックを描き終わったら、エラー処理をちゃんと実装する
        return try await commitDataRepository.sendCommitData(model)
    }
    
    
    private func createCommitDataModel() throws -> CommitDataModel {
        
        // project pathを取得
        guard let projectPath = UserDefaultsManager.shared.get(key: .projectFolderPath, type: String.self) else {
            print("CommitDataModelUseCase: Project Pathが見つかりません。")
            throw CommitDataModelUseCaseError.projectPathNotFound
        }

        
        // Git情報を取得
        let repositoryName = try gitRepository.getRepositoryName(projectPath: projectPath)
        let currentBranch = try gitRepository.getCurrentBranch(projectPath: projectPath)
        let changedFilePaths = try gitRepository.getChangedFilePaths(projectPath: projectPath)
        let owner = try gitRepository.getOwner(projectPath: projectPath)
        
        // GitHubトークンを取得
        guard let githubToken = UserDefaultsManager.shared.get(key: .githubToken, type: String.self) else {
            print("CommitDataModelUseCase: GitHubトークンが見つかりません")
            throw CommitDataModelUseCaseError.tokenNotFound
        }
        
        
        // 変更されたファイルの内容を取得
        let files = try getChangedFilesData(changedFilePaths: changedFilePaths, projectPath: projectPath)
        
        let commitDataModel = CommitDataModel(
            owner: owner,
            githubToken: githubToken,
            repository: repositoryName,
            headBranch: currentBranch,
            files: files
        )
        
        print("CommitDataModelUseCase: コミットデータモデル作成成功")
        print("   - Repository: \(owner)/\(repositoryName)")
        print("   - Branch: \(currentBranch)")
        print("   - Changed files: \(changedFilePaths.count)")
        
        return commitDataModel
    }
    
    
    /// 変更されたファイルのパスと内容を取得
    /// - Parameter changedFilePaths: 変更されたファイルのパスリスト
    /// - Parameter projectPath: プロジェクトのルートパス
    /// - Returns: [ファイルパス: ファイル内容?] の辞書
    ///   - ファイル内容がnilの場合は削除されたファイル
    /// - Throws: ファイル読み込みエラー（削除以外）
    private func getChangedFilesData(changedFilePaths: [String], projectPath: String) throws -> [String: String?] {
        var filePathAndData: [String: String?] = [:]
        
        for changedFilePath in changedFilePaths {
            // プロジェクトパスからの相対パスを絶対パスに変換
            let absolutePath = (projectPath as NSString).appendingPathComponent(changedFilePath)
            
            do {
                let fileData = try fileReader.readFile(atPath: absolutePath)
                filePathAndData[changedFilePath] = fileData
                print("ファイル読み込み成功: \(changedFilePath)")
                
            } catch FileReaderError.fileNotExist {
                // 削除されたファイルの場合のみnilを許可
                filePathAndData[changedFilePath] = nil
                print("削除されたファイル: \(changedFilePath)")
                
            } catch {
                // 削除以外のエラーは致命的エラーとして処理
                // 権限エラー、エンコーディングエラーなどを削除として扱わない
                print("ファイル読み込み失敗: \(changedFilePath)")
                print("エラー内容: \(error.localizedDescription)")
                throw CommitDataModelUseCaseError.fileReadError(
                    path: changedFilePath,
                    reason: error.localizedDescription
                )
            }
        }
        
        return filePathAndData
    }
}

// MARK: - Error Types

enum CommitDataModelUseCaseError: LocalizedError {
    case tokenNotFound
    case projectPathNotFound
    case gitInfoError(String)
    case fileReadError(path: String, reason: String)
    
    var errorDescription: String? {
        switch self {
            case .tokenNotFound:
                return "GitHubトークンが設定されていません。設定画面からトークンを設定してください。"
            case .projectPathNotFound:
                return "プロジェクトのパスが設定されていません。設定画面からパスを設定してください。"
            case .gitInfoError(let message):
                return "Git情報の取得に失敗しました: \(message)"
            case .fileReadError(let path, let reason):
                return "ファイルの読み込みに失敗しました (\(path)): \(reason)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
            case .tokenNotFound:
                return "設定画面でGitHubトークンを設定してから再試行してください。"
            case .projectPathNotFound:
                return "設定画面でプロジェクトのパスを設定してから再試行してください。"
            case .gitInfoError:
                return "Gitリポジトリの状態を確認してから再試行してください。"
            case .fileReadError:
                return "ファイルのアクセス権限、エンコーディング、ディスク容量を確認してから再試行してください。"
        }
    }
}
