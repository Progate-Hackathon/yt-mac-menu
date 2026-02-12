//
//  SettingsViewModel.swift
//  yt-mac-menu
//
//  Created by アウン on 2026/02/12.
//

import SwiftUI
import Combine

class SettingsViewModel: ObservableObject {
    @Published var selectedProjectPath: String = ""
    @Published var githubToken: String = ""
    
    @Published var settingChanged: Bool = false // 設定変更されたか
    @Published var settingErrorMessage: String?
    @Published var isSaving = false

    private var cancellables = Set<AnyCancellable>() // Combineの購読を管理するためのセット
    
    init() {
        self.addListenerToSettingFields()
    }
    
    
    func saveSetting() async {
        isSaving = true
        defer { isSaving = false }
        
        guard settingChanged else { return }
        guard projectPathIsValid() else { return }
        guard await githubTokenIsValid() else { return }

        UserDefaultUtility.shared.save(key: .PROJECT_FOLDER_PATH_KEY, value: selectedProjectPath)
        UserDefaultUtility.shared.save(key: .GITHUB_TOKEN_KEY, value: githubToken)
        
        // 設定がちゃんと保存された時
        settingErrorMessage = nil
        settingChanged = false
    }
 
}


private extension SettingsViewModel {
    private func addListenerToSettingFields() {
        // 設定の変更を検知する
        Publishers.CombineLatest($selectedProjectPath, $githubToken)
            .removeDuplicates { lhs, rhs in
                lhs.0 == rhs.0 && lhs.1 == rhs.1
            }
            .debounce(for: 0.5, scheduler: DispatchQueue.main) // 変更されて１秒経ってない間でまだ変更されたら、sinkへ行かないように
        
            .sink { [weak self] _ in
                
                guard let self = self else { return }
                settingChanged = true
            }
            .store(in: &cancellables)
    }

    
    
    
    private func projectPathIsValid() -> Bool {
        guard !selectedProjectPath.isEmpty else {
            showSettingError("プロジェクトパスが空です")
            return false
        }
        
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        
        guard fileManager.fileExists(atPath: selectedProjectPath, isDirectory: &isDirectory) else {
            showSettingError("指定されたパスは存在しません")
            return false
        }
        
        guard isDirectory.boolValue else {
            showSettingError("指定されたパスはフォルダではありません")
            return false
        }
        
        let gitPath = (selectedProjectPath as NSString).appendingPathComponent(".git")
        var isGitDirectory: ObjCBool = false
        
        guard fileManager.fileExists(atPath: gitPath, isDirectory: &isGitDirectory),
              isGitDirectory.boolValue else {
            showSettingError("このフォルダはGitリポジトリではありません")
            return false
        }
        
        return true
    }

    
    @MainActor
    private func githubTokenIsValid() async -> Bool{
        do {
            return try await GithubTokenValidator.shared.isValidToken(githubToken)
        } catch GitHubTokenError.network(let networkError) {
            showSettingError("ネットワークの問題が発生しました。やり直してください。")
            print("Tokenの検証に失敗(NetworkError): \(networkError.localizedDescription)")
        } catch GitHubTokenError.invalidResponse {
            showSettingError("エラーが発生しました。やり直してください。")
            print("Tokenの検証に失敗: Invalid Response")
        } catch {
            showSettingError("無効なトークンです。")
        }
        
        return false
    }
    
    
    
    @MainActor
    private func showSettingError(_ errorMessage: String) {
        settingErrorMessage = errorMessage
    }
}
