import SwiftUI

struct SettingsView: View {
    @StateObject private var settingsViewModel = SettingsViewModel()
    var body: some View {
        VStack {
            ProjectPathSectionView(selectedProjectPath: $settingsViewModel.selectedProjectPath)
            GitHubTokenSectionView(gitHubAccessToken: $settingsViewModel.githubToken)
        }
        .frame(width: 480)
        .padding()
        .onAppear {
            NSApp.activate()
        }
    }
}


#Preview {
    SettingsView()
}
