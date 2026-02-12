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

    private var cancellables = Set<AnyCancellable>() // Combineの購読を管理するためのセット
    
    init() {
        self.addListenerToSettingFields()
    }
    
    private func addListenerToSettingFields() {
        // 設定の変更を検知する
        Publishers.CombineLatest($selectedProjectPath, $githubToken)
            .debounce(for: 1, scheduler: DispatchQueue.main) // 変更されて１秒経ってない間でまだ変更されたら、sinkへ行かないように
            .sink { [weak self] _ in
                
                guard let self = self else { return }
                settingChanged = true
            }
            .store(in: &cancellables)
    }

    
    
    
    private func checkProjectPath() -> Bool {
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

    
    
    private func checkGithubToken() {
        
    }
    
    
    
    @MainActor
    private func showSettingError(_ errorMessage: String) {
        
    }
    
    
}
