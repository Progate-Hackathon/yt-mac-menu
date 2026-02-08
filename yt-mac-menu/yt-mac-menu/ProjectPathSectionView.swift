
import SwiftUI
import AppKit

struct ProjectPathSectionView: View {
    
    @AppStorage("projectPath") private var selectedProjectPath: String = "" //gitのプロジェクトパス

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Project Path")
                .font(.headline)

            HStack(spacing: 8) {
                TextField("Select project path", text: $selectedProjectPath)
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 300)

                Button("Browse…") {
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
        panel.prompt = "Choose"
        panel.message = "Select your project directory"

        if panel.runModal() == .OK, let url = panel.url {
                        selectedProjectPath = url.path
        }
    }
}

#Preview {
    ProjectPathSectionView()
}

