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
}
