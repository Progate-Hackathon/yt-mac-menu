import SwiftUI

struct SettingsView: View {
    var body: some View {
        VStack {
            ProjectPathSectionView()
            GitHubTokenSectionView() //まだissue-#4のプルリクが通ってないのでファイルが見つからずエラーが出ますが許してください
        }
        .frame(width: 480)
        .padding()
    }
}
