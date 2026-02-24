import SwiftUI

struct GitHubTokenSectionView: View {
    
    @Binding var gitHubAccessToken: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            Text("GitHub Access Token")
                .font(.headline)

            SecureField("トークンを入力", text: $gitHubAccessToken)
                .textFieldStyle(.roundedBorder)
                .frame(minWidth: 300)

            Text("入力されたトークンは保存されず、GitHub認証にのみ使用されます。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    @Previewable @State var githubAccessToken = ""
    GitHubTokenSectionView(gitHubAccessToken: $githubAccessToken)
}
