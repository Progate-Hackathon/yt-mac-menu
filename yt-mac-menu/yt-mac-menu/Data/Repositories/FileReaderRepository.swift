//
//  FileReaderRepository.swift
//  yt-mac-menu
//
//  Created by アウン on 2026/02/14.
//

import Foundation


class FileReaderRepository: FileReaderRepositoryProtocol {
    
    func readFile(atPath path: String) throws -> String {
        let fileURL = URL(fileURLWithPath: path)
        return try String(contentsOf: fileURL, encoding: .utf8)
    }

}
