import SwiftUI

struct BaseBranchSectionView: View {
    
    @Binding var baseBranch: String
    let availableBranches: [String]
    let isFetching: Bool
    let error: FetchBranchesUseCaseError?
    let onRetry: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ベースブランチ")
                    .font(.headline)
                
                Spacer()
                
                if isFetching {
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(width: 16, height: 16)
                }
            }
            
            // Show error if present
            if let error = error {
                errorView(error)
            }
            
            // Always show picker but overlay loading/empty states
            ZStack(alignment: .leading) {
                // Base picker - always present for stable identity
                pickerView
                    .opacity(isFetching || availableBranches.isEmpty ? 0 : 1)
                
                // Loading overlay
                if isFetching {
                    loadingPlaceholder
                }
                
                // Empty overlay
                if !isFetching && availableBranches.isEmpty && error == nil {
                    emptyBranchesView
                }
            }
            
            helpText
        }
        .padding()
    }
    
    @ViewBuilder
    private var pickerView: some View {
        
        Menu {
            ForEach(availableBranches, id: \.self) { branch in
                Button(branch) {
                    baseBranch = branch
                    print("DEBUG: Selected branch: \(branch)")
                }
            }
        } label: {
            Text(baseBranch)
            
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
        }
    }
    
    @ViewBuilder
    private var loadingPlaceholder: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.triangle.branch")
                .foregroundColor(.secondary)
            
            Text("ブランチを取得中...")
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private var emptyBranchesView: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            
            Text("ブランチが見つかりませんでした")
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private func errorView(_ error: FetchBranchesUseCaseError) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                
                Text(error.errorDescription ?? "エラーが発生しました")
                    .foregroundColor(.red)
                    .font(.subheadline)
            }
            
            if let recovery = error.recoverySuggestion {
                Text(recovery)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Button("再試行") {
                onRetry()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(12)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
    
    @ViewBuilder
    private var helpText: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("PRを作成する際のベースとなるブランチです")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("ブランチが見つからない場合は、リモートブランチを作成してください")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    @Previewable @State var baseBranch: String = "main"
    
    BaseBranchSectionView(
        baseBranch: $baseBranch,
        availableBranches: ["main", "develop", "feature/test"],
        isFetching: false,
        error: nil,
        onRetry: {}
    )
}
