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
        OnboardingWindowController.shared.showIfNeeded()
    }
    
    var body: some Scene {
        MenuBarExtra{
            SettingsLink()
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            Button(action: {
              let appDomain = Bundle.main.bundleIdentifier
              UserDefaults.standard.removePersistentDomain(forName: appDomain!)
            })  {
              Text("データ削除")
            }
        } label: {
            Image("menubar_icon")
                .renderingMode(.template)
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
