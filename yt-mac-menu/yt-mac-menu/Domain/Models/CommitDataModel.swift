//
//  CommitDataModel.swift
//  yt-mac-menu
//
//  Created by アウン on 2026/02/14.
//

import Foundation

struct CommitDataModel: Codable {
    let githubToken: String
    let repository: String
    let branch: String
    let diff: String
}
