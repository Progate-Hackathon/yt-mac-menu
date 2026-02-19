//
//  UserDefaultsManager.swift
//  yt-mac-menu
//
//  Created by アウン on 2026/02/12.
//

import Foundation

enum UserDefaultKeys: String {
    case githubToken
    case projectFolderPath
    case baseBranch
    case shouldCreatePR
}

final class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    
    private init() {}
    
    func save(key: UserDefaultKeys, value: String) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }
    
    
    func get(key: UserDefaultKeys) -> String? {
        let savedValue = UserDefaults.standard.string(forKey: key.rawValue)
        if let savedValue {
            return savedValue
        } else {
            print("キー：\(key.rawValue)の値は保存されていません")
            return nil
        }
    }
}
