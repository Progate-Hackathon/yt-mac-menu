//
//  FileReaderRepositoryProtocol.swift
//  yt-mac-menu
//
//  Created by アウン on 2026/02/14.
//

import Foundation

protocol FileReaderRepositoryProtocol {
    func readFile(atPath path: String) throws -> String
}
