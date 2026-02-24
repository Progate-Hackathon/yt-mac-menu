//
//  CommitDataModel.swift
//  yt-mac-menu
//
//  Created by アウン on 2026/02/14.
//

import Foundation

/// エンドポイントに送信するためのデータ構造
struct CommitDataModel: Codable {
    /// リポジトリのオーナー名
    let owner: String
    
    /// GitHub個人アクセストークン
    let githubToken: String
    
    /// リポジトリ名
    let repository: String
    
    /// HEADブランチ名
    let headBranch: String
    
    /// 変更されたファイルのデータ
    /// - Key: ファイルパス（プロジェクトルートからの相対パス）
    /// - Value: ファイルの内容（削除された場合はnil）
    let files: FileChanges
}

/// ファイルパスとその内容のマッピング
/// nilの場合は削除されたファイルを表す
typealias FileChanges = [String: String?]
