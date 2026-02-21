import SwiftUI

struct GestureActionSection: View {
    let gestureType: GestureType
    @ObservedObject var viewModel: ShortcutViewModel
    
    @State private var activePopoverIndex: Int? = nil
    
    private var actions: [GestureAction] {
        viewModel.actions(for: gestureType)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("\(gestureType.emoji) \(gestureType.displayName)検出時のアクション")
                    .font(.headline)
                
                Spacer()
                
                // Add action button
                if actions.count < GestureAction.maxActionsPerGesture {
                    Button(action: { viewModel.addAction(for: gestureType) }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("追加")
                        }
                        .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.blue)
                }
            }
            
            if actions.isEmpty {
                Text("アクションが設定されていません")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                // Action list
                ForEach(Array(actions.enumerated()), id: \.element.id) { index, action in
                    ActionRowView(
                        index: index,
                        action: action,
                        gestureType: gestureType,
                        viewModel: viewModel,
                        isPopoverPresented: Binding(
                            get: { activePopoverIndex == index },
                            set: { if $0 { activePopoverIndex = index } else { activePopoverIndex = nil } }
                        )
                    )
                    
                    if index < actions.count - 1 {
                        Divider()
                            .padding(.leading, 24)
                    }
                }
            }
        }
    }
}

// MARK: - Action Row View

private struct ActionRowView: View {
    let index: Int
    let action: GestureAction
    let gestureType: GestureType
    @ObservedObject var viewModel: ShortcutViewModel
    @Binding var isPopoverPresented: Bool
    
    @State private var localCommand: String = ""
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Index badge
            Text("\(index + 1)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(width: 20, height: 20)
                .background(Circle().fill(Color.secondary.opacity(0.2)))
            
            VStack(alignment: .leading, spacing: 8) {
                // Action type picker
                HStack {
                    Picker("", selection: Binding(
                        get: { action.actionType },
                        set: { viewModel.updateActionType($0, at: index, for: gestureType) }
                    )) {
                        ForEach(ActionType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 140)
                    
                    Spacer()
                    
                    // Delete button
                    Button(action: { viewModel.removeAction(at: index, for: gestureType) }) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(.red.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                }
                
                // Conditional config based on action type
                switch action.actionType {
                case .shortcut:
                    shortcutConfig
                case .command:
                    commandConfig
                case .commit:
                    Text("変更内容をAIが要約してGitHubにコミット")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            localCommand = action.commandString ?? ""
        }
    }
    
    // MARK: - Shortcut Config
    
    private var shortcutConfig: some View {
        HStack {
            Text("キー:")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Button(action: {
                isPopoverPresented = true
                viewModel.onRecordingComplete = { isPopoverPresented = false }
                viewModel.startRecording(for: gestureType, actionIndex: index)
            }) {
                Text(action.hotkey?.displayString ?? "クリックして設定")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(action.hotkey == nil ? .secondary : .white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.white.opacity(0.1))
                    )
            }
            .buttonStyle(.plain)
            .popover(isPresented: $isPopoverPresented, arrowEdge: .top) {
                RecorderOverlaySectionView(
                    showSuccess: $viewModel.showSuccess,
                    tempModifiers: $viewModel.tempModifiers,
                    tempKeyDisplay: $viewModel.tempKeyDisplay,
                    currentHotkey: Binding(
                        get: { action.hotkey ?? Hotkey(modifiers: [], keyCode: 0, keyDisplay: "") },
                        set: { _ in }
                    ),
                    stopRecording: viewModel.stopRecording
                )
            }
        }
    }
    
    // MARK: - Command Config
    
    private var commandConfig: some View {
        HStack {
            Text("コマンド:")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            TextField("例: open -a Safari", text: $localCommand)
                .font(.system(size: 12))
                .textFieldStyle(.plain)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .frame(width: 180)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white.opacity(0.1))
                )
                .onSubmit {
                    viewModel.updateCommand(localCommand, at: index, for: gestureType)
                }
                .onChange(of: localCommand) { _, newValue in
                    viewModel.updateCommand(newValue, at: index, for: gestureType)
                }
        }
    }
}
