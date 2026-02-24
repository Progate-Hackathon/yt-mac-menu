import SwiftUI

struct CreatePRSectionView: View {
    
    @Binding var shouldCreatePR: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("プルリクエスト設定")
                    .font(.headline)
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Toggle(isOn: $shouldCreatePR) {
                        Text("自動的にプルリクエストを作成")
                            .font(.body)
                    }
                    .toggleStyle(.checkbox)
                    
                    Text(shouldCreatePR ? "コミット後、自動的にPRが作成されます" : "コミットのみ実行されます")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
        }
        .padding()
    }
}

#Preview {
    @Previewable @State var shouldCreatePR: Bool = false
    CreatePRSectionView(shouldCreatePR: $shouldCreatePR)
}
