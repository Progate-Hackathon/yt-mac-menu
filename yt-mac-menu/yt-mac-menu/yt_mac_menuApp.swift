//
//  yt_mac_menuApp.swift
//  yt-mac-menu
//
//  Created by cmStudent on 2026/02/08.
//

import SwiftUI

@main
struct yt_mac_menuApp: App {
    private let container = DependencyContainer.shared
    @StateObject private var appViewModel: AppViewModel
    @AppStorage("isFirstLaunch") var isFirstLaunch: Bool = true
    
    init() {
        let coordinator = DependencyContainer.shared.makeAppCoordinator()
        _appViewModel = StateObject(wrappedValue: AppViewModel(coordinator: coordinator))
    }
    
    var body: some Scene {
        WindowGroup {
            if isFirstLaunch {
                // 初回起動時のみ表示
                SettingsView()
            }
        }
        
        
        MenuBarExtra("yt-mac-menu", systemImage: "star.fill") {
            SettingsLink()
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        
        Settings {
            SettingsView()
        }
    }
}

