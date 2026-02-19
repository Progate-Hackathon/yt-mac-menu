import SwiftUI

struct BaseBranchSectionView: View {
    
    @Binding var baseBranch: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ベースブランチ")
                    .font(.headline)
                
                Spacer()
                
                Text("例: main, develop")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 8) {
                Image(systemName: "arrow.triangle.branch")
                    .foregroundColor(.secondary)
                
                TextField("ベースブランチ名", text: $baseBranch)
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 200)
            }
            
            Text("PRを作成する際のベースとなるブランチです")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    @Previewable @State var baseBranch: String = "main"
    BaseBranchSectionView(baseBranch: $baseBranch)
}
