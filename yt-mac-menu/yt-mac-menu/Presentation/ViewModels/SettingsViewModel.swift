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
    
    @Published var hasUnsavedChanges: Bool = false
    @Published var errorMessage: String?
    @Published var isSaving = false

    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.loadSettings()
        self.observeSettingChanges()
    }
    
    
    func saveSettings() async {
        isSaving = true
        defer { isSaving = false }
        
        guard hasUnsavedChanges else { return }
        guard isProjectPathValid() else { return }
        guard await isGitHubTokenValid() else { return }

        UserDefaultUtility.shared.save(key: .githubToken, value: githubToken)
        UserDefaultUtility.shared.save(key: .projectFolderPath, value: selectedProjectPath)
        
        errorMessage = nil
        hasUnsavedChanges = false
    }
 
}


private extension SettingsViewModel {
    private func observeSettingChanges() {
        Publishers.CombineLatest($selectedProjectPath, $githubToken)
            .removeDuplicates { lhs, rhs in
                lhs.0 == rhs.0 && lhs.1 == rhs.1
            }
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
        
            .sink { [weak self] _ in
                
                guard let self = self else { return }
                hasUnsavedChanges = true
            }
            .store(in: &cancellables)
    }

    
    
    @MainActor
    private func loadSettings() {
        self.githubToken = UserDefaultUtility.shared.get(key: .githubToken) ?? ""
        self.selectedProjectPath = UserDefaultUtility.shared.get(key: .projectFolderPath) ?? ""
    }
    
    
    
    private func isProjectPathValid() -> Bool {
        guard !selectedProjectPath.isEmpty else {
            showError("プロジェクトパスが空です")
            return false
        }
        
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        
        guard fileManager.fileExists(atPath: selectedProjectPath, isDirectory: &isDirectory) else {
            showError("指定されたパスは存在しません")
            return false
        }
        
        guard isDirectory.boolValue else {
            showError("指定されたパスはフォルダではありません")
            return false
        }
        
        let gitPath = (selectedProjectPath as NSString).appendingPathComponent(".git")
        var isGitDirectory: ObjCBool = false
        
        guard fileManager.fileExists(atPath: gitPath, isDirectory: &isGitDirectory),
              isGitDirectory.boolValue else {
            showError("このフォルダはGitリポジトリではありません")
            return false
        }
        
        return true
    }

    
    @MainActor
    private func isGitHubTokenValid() async -> Bool{
        do {
            return try await GithubTokenValidator.shared.isValidToken(githubToken)
        } catch GitHubTokenError.network(let networkError) {
            showError("ネットワークの問題が発生しました。やり直してください。")
            print("Tokenの検証に失敗(NetworkError): \(networkError.localizedDescription)")
        } catch GitHubTokenError.invalidResponse {
            showError("エラーが発生しました。やり直してください。")
            print("Tokenの検証に失敗: Invalid Response")
        } catch {
            showError("無効なトークンです。")
        }
        
        return false
    }
    
    
    
    @MainActor
    private func showError(_ message: String) {
        errorMessage = message
    }
}
