import SwiftUI

struct GitHubTokenSectionView: View {
    
    // 後で暗号化処理に渡す想定
    @State private var gitHubAccessToken: String = ""

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
    GitHubTokenSectionView()
}
