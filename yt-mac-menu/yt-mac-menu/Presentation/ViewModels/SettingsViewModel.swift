import SwiftUI
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    
    // MARK: - Properties
    
    // Settings Data
    @Published var selectedProjectPath: String = ""
    @Published var githubToken: String = ""

    // UI State
    @Published var hasUnsavedChanges: Bool = false
    @Published var errorMessage: String?
    @Published var isSaving = false

    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Lifecycle
    
    init() {
        self.githubToken = UserDefaultsManager.shared.get(key: .githubToken, type: String.self) ?? ""
        self.selectedProjectPath = UserDefaultsManager.shared.get(key: .projectFolderPath, type: String.self) ?? ""

        setupChangeObserver()
    }
    
    // MARK: - Setup

    private func setupChangeObserver() {
        // Token/Pathの変更を監視してunsavedフラグを立てる
        Publishers.CombineLatest($selectedProjectPath, $githubToken)
            .dropFirst()
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .removeDuplicates { $0.0 == $1.0 && $0.1 == $1.1 }
            .sink { [weak self] _ in
                self?.hasUnsavedChanges = true
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions (Saving)

    /// Token/Pathの保存（保存ボタン用）
    func saveSettings() async {
        isSaving = true
        defer { isSaving = false }
        
        guard hasUnsavedChanges else { return }
        
        // Validation
        guard isProjectPathValid() else { return }
        guard await isGitHubTokenValid() else { return }
        
        UserDefaultsManager.shared.save(key: .githubToken, value: githubToken)
        UserDefaultsManager.shared.save(key: .projectFolderPath, value: selectedProjectPath)
        
        errorMessage = nil
        hasUnsavedChanges = false
        print("DEBUG: Settings saved successfully")
    }
    
    // MARK: - Validation
    
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
    
    private func isGitHubTokenValid() async -> Bool {
        do {
            return try await GitHubAPIClient.shared.isValidToken(githubToken)
        } catch GitHubTokenError.network(let networkError) {
            showError("ネットワークの問題が発生しました。やり直してください。")
            print("Tokenの検証に失敗(NetworkError): \(networkError.localizedDescription)")
        } catch GitHubTokenError.invalidResponse {
            showError("エラーが発生しました。やり直してください。")
            print("Tokenの検証に失敗: Invalid Response")
        } catch {
            showError("無効なトークンです")
        }
        return false
    }
    
    private func showError(_ message: String) {
        errorMessage = message
    }
}
