import SwiftUI

struct SettingsView: View {
    @StateObject private var settingsViewModel = SettingsViewModel()
    var body: some View {
        VStack {
            ProjectPathSectionView(selectedProjectPath: $settingsViewModel.selectedProjectPath)
            GitHubTokenSectionView(gitHubAccessToken: $settingsViewModel.githubToken)
            
            errorMessage
            
            saveButton

        }
        .frame(width: 480)
        .padding()
        .onAppear {
            NSApp.activate()
        }
    }
    
    @ViewBuilder
    private var errorMessage: some View {
        if let message = settingsViewModel.errorMessage {
            Text(message)
                .foregroundStyle(.red)
        }
    }
    
    @ViewBuilder
    private var saveButton: some View {
        let buttonIsDisabled = settingsViewModel.isSaving || !settingsViewModel.hasUnsavedChanges
        Button {
            Task {
                await settingsViewModel.saveSettings()
                NSApp.keyWindow?.makeFirstResponder(nil)
            }

        } label: {
            Text("保存")
        }
        .foregroundStyle(buttonIsDisabled ? .gray : .blue)
        .disabled(buttonIsDisabled)
    }
}


#Preview {
    SettingsView()
}
