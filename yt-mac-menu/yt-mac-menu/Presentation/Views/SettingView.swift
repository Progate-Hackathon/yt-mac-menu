import SwiftUI

struct SettingsView: View {
    @StateObject private var settingsViewModel = SettingsViewModel()
    var body: some View {
        TabView{
            VStack {
                ProjectPathSectionView(selectedProjectPath: $settingsViewModel.selectedProjectPath)
                GitHubTokenSectionView(gitHubAccessToken: $settingsViewModel.githubToken)
                
                errorMessage
                
                saveButton
                
            }
            .padding()
            .tabItem {
                Label("一般", systemImage: "gear")
            }
            .tag("general")
            
            VStack {
                ShortcutView()
            }
            .padding()
            .tabItem {
                Label("ショートカット", systemImage: "hand.draw")
            }
            .tag("shortcuts")
        }
        .frame(width: 480)
        .background(.ultraThinMaterial)
        .background(Color.black.opacity(0.1))
        .background(WindowAccessor { window in
            guard let window = window else { return }
            window.isOpaque = false
            window.backgroundColor = .clear
            window.titlebarAppearsTransparent = true
            window.level = .floating
        })
        .onAppear {
            NSApp.activate(ignoringOtherApps: true)
            DispatchQueue.main.async {
                if let window = NSApp.windows.first(where: { $0.isVisible && $0.level == .floating }) {
                    window.makeKeyAndOrderFront(nil)
                    window.orderFrontRegardless()
                }
            }
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

struct WindowAccessor: NSViewRepresentable {
    var callback: (NSWindow?) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            self.callback(view.window)
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

#Preview {
    SettingsView()
}
