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
}
