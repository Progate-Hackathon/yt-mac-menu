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
    
    init() {
        let coordinator = DependencyContainer.shared.makeAppCoordinator()
        _appViewModel = StateObject(wrappedValue: AppViewModel(coordinator: coordinator))
    }
    
    var body: some Scene {
        MenuBarExtra("yt-mac-menu", systemImage: "star.fill") {
            SettingsLink()
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .onChange(of: appViewModel.isCameraVisible) { _, newValue in
            if newValue {
                FloatingWindowController.shared.open()
            } else {
                FloatingWindowController.shared.close()
            }
        }
        
        Settings {
            SettingsView()
        }
    }
}
