import SwiftUI

struct SettingsView: View {
    @StateObject private var settingsViewModel: SettingsViewModel
    @State private var settingsWindow: NSWindow?
    
    private var basicSettingsAreSet: Bool {
        // 保存済みの設定があるかをチェック
        settingsViewModel.settingsSaved
    }
    
    
    init() {
        let fetchBranchesUseCase = DependencyContainer.shared.makeFetchBranchesUseCase()
        _settingsViewModel = StateObject(wrappedValue: SettingsViewModel(fetchBranchesUseCase: fetchBranchesUseCase))
    }
    
    var body: some View {
        TabView {
            VStack {
                ProjectPathSectionView(selectedProjectPath: $settingsViewModel.selectedProjectPath)
                GitHubTokenSectionView(gitHubAccessToken: $settingsViewModel.githubToken)
                if basicSettingsAreSet {
                    VStack {
                        Divider()
                            .padding(.vertical, 8)
                        
                        Text("高度な設定")
                            .font(.headline)
                        
                        BaseBranchSectionView(
                            baseBranch: $settingsViewModel.baseBranch,
                            availableBranches: settingsViewModel.availableBranches,
                            isFetching: settingsViewModel.isFetchingBranches,
                            error: settingsViewModel.branchFetchError,
                            onRetry: {
                                Task {
                                    await settingsViewModel.fetchBranches()
                                }
                            }
                        )
                        CreatePRSectionView(shouldCreatePR: $settingsViewModel.shouldCreatePR)
                    }
                    .transition(.opacity)
                    .task {
                        // Fetch branches when advanced settings appear
                        await settingsViewModel.fetchBranches()
                    }
                }
                
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
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .tabItem {
                Label("ショートカット", systemImage: "hand.draw")
            }
            .tag("shortcuts")
        }
        .animation(.default, value: basicSettingsAreSet)
        .frame(width: 480)
        .background(.ultraThinMaterial)
        .onAppear {
            NSApp.activate(ignoringOtherApps: true)
            DispatchQueue.main.async {
                // 保存済みのウィンドウ参照を使い、アクティブなSpaceへ確実に移動させる
                settingsWindow?.collectionBehavior = [.moveToActiveSpace]
                settingsWindow?.makeKeyAndOrderFront(nil)
                settingsWindow?.orderFrontRegardless()
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

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard !context.coordinator.hasConfigured else { return }
            context.coordinator.hasConfigured = true
            self.callback(view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    class Coordinator {
        var hasConfigured = false
    }
}

#Preview {
    SettingsView()
}
