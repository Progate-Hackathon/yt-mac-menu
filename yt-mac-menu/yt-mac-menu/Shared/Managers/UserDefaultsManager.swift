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
    
    func save<T: Codable>(key: UserDefaultKeys, value: T) {
        // 構造体をJSONデータに変換して保存
        if let encoded = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(encoded, forKey: key.rawValue)
            print("💾 [UserDefaults] 保存成功: \(key.rawValue)")
        } else {
            print("⚠️ [UserDefaults] 保存失敗: エンコードできませんでした")
        }
    }
    
    // 読み込み用
    func get<T: Codable>(key: UserDefaultKeys, type: T.Type) -> T? {
        // データを読み込んで、構造体に復元する
        guard let data = UserDefaults.standard.data(forKey: key.rawValue) else {
            return nil
        }
        
        if let decoded = try? JSONDecoder().decode(type, from: data) {
            return decoded
        } else {
            print("⚠️ [UserDefaults] 読み込み失敗: デコードできませんでした")
            return nil
        }
    }
}
