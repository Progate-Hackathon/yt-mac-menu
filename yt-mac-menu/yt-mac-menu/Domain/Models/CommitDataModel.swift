//
//  CommitDataModel.swift
//  yt-mac-menu
//
//  Created by アウン on 2026/02/14.
//

import Foundation

struct CommitDataModel: Codable {
    let owner: String
    let githubToken: String
    let repository: String
    let baseBranch: String
    let files: FileData
}


struct FileData: Codable {
    let path: String
    let DataString: String
}
