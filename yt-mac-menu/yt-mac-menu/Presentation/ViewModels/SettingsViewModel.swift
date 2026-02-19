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
    @Published var baseBranch: String = ""
    @Published var shouldCreatePR: Bool = false
    
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
        guard isBaseBranchValid() else { return }

        UserDefaultsManager.shared.save(key: .githubToken, value: githubToken)
        UserDefaultsManager.shared.save(key: .projectFolderPath, value: selectedProjectPath)
        UserDefaultsManager.shared.save(key: .baseBranch, value: baseBranch)
        UserDefaultsManager.shared.save(key: .shouldCreatePR, value: shouldCreatePR)
        
        errorMessage = nil
        hasUnsavedChanges = false
    }
 
}


private extension SettingsViewModel {
    private func observeSettingChanges() {
        Publishers.CombineLatest4($selectedProjectPath, $githubToken, $baseBranch, $shouldCreatePR)
            .removeDuplicates { lhs, rhs in
                lhs.0 == rhs.0 && lhs.1 == rhs.1 && lhs.2 == rhs.2 && lhs.3 == rhs.3
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
        self.githubToken = UserDefaultsManager.shared.get(key: .githubToken) ?? ""
        self.selectedProjectPath = UserDefaultsManager.shared.get(key: .projectFolderPath) ?? ""
        self.baseBranch = UserDefaultsManager.shared.get(key: .baseBranch) ?? "main"
        self.shouldCreatePR = UserDefaultsManager.shared.getBool(key: .shouldCreatePR)
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
    
    private func isBaseBranchValid() -> Bool {
        guard !baseBranch.isEmpty else {
            showError("ベースブランチ名が空です")
            return false
        }
        
        // ブランチ名の基本的なバリデーション
        let invalidChars = CharacterSet(charactersIn: " ~^:?*[\\")
        if baseBranch.rangeOfCharacter(from: invalidChars) != nil {
            showError("ブランチ名に無効な文字が含まれています")
            return false
        }
        
        return true
    }

    
    @MainActor
    private func isGitHubTokenValid() async -> Bool{
        do {
            return try await GitHubAPIClient.shared.isValidToken(githubToken)
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
