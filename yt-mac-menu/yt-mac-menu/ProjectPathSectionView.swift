import SwiftUI
import AppKit

struct ProjectPathSectionView: View {
    
    @AppStorage("projectPath") private var selectedProjectPath: String = "" // gitのプロジェクトパス

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("プロジェクトフォルダ")
                .font(.headline)

            HStack(spacing: 8) {
                TextField("プロジェクトフォルダを選択", text: $selectedProjectPath)
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 300)

                Button("選択…") {
                    showProjectDirectoryPicker()
                }
            }
        }
        .padding()
    }
}

private extension ProjectPathSectionView {

    func showProjectDirectoryPicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "選択"
        panel.message = "プロジェクトのフォルダを選択してください"

        if panel.runModal() == .OK, let url = panel.url {
            selectedProjectPath = url.path
        }
    }
}

#Preview {
    ProjectPathSectionView()
}
