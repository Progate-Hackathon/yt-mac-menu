//
//  yt_mac_menuApp.swift
//  yt-mac-menu
//
//  Created by cmStudent on 2026/02/08.
//

import SwiftUI
import AppKit

@main
struct yt_mac_menuApp: App {
    private let container = DependencyContainer.shared
    @StateObject private var appViewModel: AppViewModel
    
    init() {
        let coordinator = DependencyContainer.shared.makeAppCoordinator()
        _appViewModel = StateObject(wrappedValue: AppViewModel(coordinator: coordinator))
        
        // Handle first launch: show Settings on first run
        let launched = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        if !launched {
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
            // Present Settings after app launches
            DispatchQueue.main.async {
                NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
            }
        }
    }
    
    var body: some Scene {
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
