//
//  yt_mac_menuApp.swift
//  yt-mac-menu
//
//  Created by cmStudent on 2026/02/08.
//

import SwiftUI

@main
struct yt_mac_menuApp: App {
    @StateObject private var appViewModel = AppViewModel()
    
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
                CameraWindowController.shared.open()
            } else {
                CameraWindowController.shared.close()
            }
        }
        
        Settings {
            SettingsView()
        }
    }
}
