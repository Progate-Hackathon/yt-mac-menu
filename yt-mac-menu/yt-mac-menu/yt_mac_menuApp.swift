//
//  yt_mac_menuApp.swift
//  yt-mac-menu
//
//  Created by cmStudent on 2026/02/08.
//

import SwiftUI

@main
struct yt_mac_menuApp: App {
<<<<<<< HEAD
    @StateObject private var appViewModel = AppViewModel()
    
    var body: some Scene {
        MenuBarExtra("yt-mac-menu", systemImage: "star.fill") {
=======
    var body: some Scene {
        MenuBarExtra("yt-mac-menu", systemImage: "star.fill") {
            Button("(プレビューなし)検知開始をシミュレート") {
                CameraWindowController.shared.open()
            }
            Button("(プレビューあり)検知開始をシミュレート") {
                CameraWindowController.shared.open()
            }
>>>>>>> develop
            SettingsLink()
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .onChange(of: appViewModel.isCameraVisible) { oldValue, newValue in
            if newValue {
                CameraWindowController.shared.open()
            }
        }
        
        Settings {
            SettingsView()
        }
    }
}
