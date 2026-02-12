//
//  yt_mac_menuApp.swift
//  yt-mac-menu
//
//  Created by cmStudent on 2026/02/08.
//

import SwiftUI

@main
struct yt_mac_menuApp: App {
    
    @StateObject private var gestureDetectionViewModel = GestureDetectionViewModel()
    @StateObject private var gestureCameraViewModel = GestureCameraViewModel()

    var body: some Scene {
        MenuBarExtra("yt-mac-menu", systemImage: "star.fill") {
            Button("(プレビューなし)検知開始をシミュレート") {
                gestureDetectionViewModel.appState = .detecting
            }
            Button("(プレビューあり)検知開始をシミュレート") {
                CameraWindowController.shared.open()
            }
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
