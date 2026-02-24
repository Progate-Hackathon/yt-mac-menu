//
//  FileReaderRepository.swift
//  yt-mac-menu
//
//  Created by アウン on 2026/02/14.
//

import Foundation

enum FileReaderError: LocalizedError {
    case fileNotExist(path: String)
    case unreadable(path: String, reason: String)
    
    var errorDescription: String? {
        switch self {
        case .fileNotExist(let path):
            return "ファイルが存在しません: \(path)"
        case .unreadable(let path, let reason):
            return "ファイルを読み込めません (\(path)): \(reason)"
        }
    }
}

class FileReaderRepository: FileReaderRepositoryProtocol {
    
    func readFile(atPath path: String) throws -> String {
        let fileURL = URL(fileURLWithPath: path)
        
        // ファイルの存在確認
        guard FileManager.default.fileExists(atPath: path) else {
            throw FileReaderError.fileNotExist(path: path)
        }
        
        // ファイル読み込み
        do {
            return try String(contentsOf: fileURL, encoding: .utf8)
        } catch {
            throw FileReaderError.unreadable(path: path, reason: error.localizedDescription)
        }
    }
}
