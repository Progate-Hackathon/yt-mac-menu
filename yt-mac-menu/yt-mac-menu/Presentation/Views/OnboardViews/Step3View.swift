//
//  Step3View.swift
//  yt-mac-menu
//
//  Created by cmStudent on 2026/02/21.
//

import SwiftUI

struct Step3View: View {
    @State private var settingsWindow: NSWindow?
    @Binding var selectedProjectPath: String
    @Binding var githubToken: String
    @Binding var baseBranch: String
    @Binding var shouldCreatePR: Bool
    @Binding var hasUnsavedChanges: Bool
    @Binding var errorMessage: String?
    @Binding var isSaving: Bool
    @Binding var settingsSaved: Bool
    
    var saveSettinss: () -> Void
    
    private var basicSettingsAreSet: Bool {
        selectedProjectPath.isEmpty && githubToken.isEmpty
    }
    
    var body: some View {
            VStack {
                ProjectPathSectionView(selectedProjectPath: $selectedProjectPath)
                GitHubTokenSectionView(gitHubAccessToken: $githubToken)
                if basicSettingsAreSet {
                    VStack {
                        Divider()
                            .padding(.vertical, 8)
                        
                        Text("高度な設定")
                            .font(.headline)
                        
                        BaseBranchSectionView(baseBranch: $baseBranch)
                        CreatePRSectionView(shouldCreatePR: shouldCreatePR)
                    }
                    .transition(.opacity)
                }
                
                errorMessage
                
                saveButton
                
            }
            .padding()
    }
    
    @ViewBuilder
    private var step3errorMessage: some View {
        if let message = errorMessage {
            Text(message)
                .foregroundStyle(.red)
        }
    }
    
    @ViewBuilder
    private var saveButton: some View {
        let buttonIsDisabled = isSaving || !hasUnsavedChanges
        Button {
            Task {
                await saveSettings()
                NSApp.keyWindow?.makeFirstResponder(nil)
            }
            
        } label: {
            Text("保存")
        }
        .foregroundStyle(buttonIsDisabled ? .gray : .blue)
        .disabled(buttonIsDisabled)
    }
}

struct Step3WindowAccessor: NSViewRepresentable {
    var callback: (NSWindow?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard !context.coordinator.hasConfigured else { return }
            context.coordinator.hasConfigured = true
            self.callback(view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    class Coordinator {
        var hasConfigured = false
    }
}
