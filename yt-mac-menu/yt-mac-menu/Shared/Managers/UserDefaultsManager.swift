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
    case hotkeyConfig
    case actionType
    case baseBranch
    case shouldCreatePR
    case snapTriggerHotkey
    case commandString
    case onboardingCompleted

    // Peace gesture settings
    case peaceActionType
    case peaceHotkeyConfig
    case peaceCommandString

    // Thumbs up gesture settings
    case thumbsUpActionType
    case thumbsUpHotkeyConfig
    case thumbsUpCommandString
}

final class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    
    private init() {}
    
    func save<T: Codable>(key: UserDefaultKeys, value: T) {
        if let encoded = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(encoded, forKey: key.rawValue)
            UserDefaults.standard.synchronize()  // 即座に書き込みを強制
            print("[UserDefaults] 保存成功: \(key.rawValue)")
        } else {
            print("⚠️ [UserDefaults] 保存失敗: \(key.rawValue) をエンコードできませんでした")
        }
    }

    func get<T: Codable>(key: UserDefaultKeys, type: T.Type) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key.rawValue) else {
            return nil
        }
        if let decoded = try? JSONDecoder().decode(type, from: data) {
            return decoded
        } else {
            print("⚠️ [UserDefaults] 読み込み失敗: \(key.rawValue) をデコードできませんでした")
            return nil
        }
    }
    
    func getBool(key: UserDefaultKeys) -> Bool {
        return UserDefaults.standard.bool(forKey: key.rawValue)
    }

    func save(key: UserDefaultKeys, value: Bool) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }
}
