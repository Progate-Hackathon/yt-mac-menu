import SwiftUI

struct GestureActionSection: View {
    let gestureName: String
    let gestureEmoji: String
    
    @Binding var actionType: ActionType
    @Binding var hotkey: Hotkey
    @Binding var commandString: String
    @Binding var showRecorderPopover: Bool
    @Binding var showSuccess: Bool
    @Binding var tempModifiers: NSEvent.ModifierFlags
    @Binding var tempKeyDisplay: String
    
    let onActionTypeChange: (ActionType) -> Void
    let onSaveCommand: () -> Void
    let onStartRecording: () -> Void
    let onStopRecording: () -> Void
    let onTestShortcut: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Action type picker
            HStack {
                Text("\(gestureEmoji) \(gestureName)")
                    .font(.headline)
                    .frame(width: 200, alignment: .leading)

                Picker("", selection: $actionType) {
                    ForEach(ActionType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(width: 200)
                .onChange(of: actionType) { _, newValue in
                    onActionTypeChange(newValue)
                }
            }

            Text(actionType.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            // Conditional UI based on action type
            if actionType == .shortcut {
                shortcutSection
            }
            
            if actionType == .command {
                commandSection
            }
        }
    }
    
    // MARK: - Shortcut Section
    
    private var shortcutSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("ショートカットキー")
                    .font(.headline)
                    .frame(width: 200, alignment: .leading)
                
                Button(action: onStartRecording) {
                    Text(hotkey.displayString)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 200, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.white.opacity(0.1))
                                .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                        )
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showRecorderPopover, arrowEdge: .top) {
                    RecorderOverlaySectionView(
                        showSuccess: $showSuccess,
                        tempModifiers: $tempModifiers,
                        tempKeyDisplay: $tempKeyDisplay,
                        currentHotkey: $hotkey,
                        stopRecording: onStopRecording
                    )
                }
            }
            
            // Test button
            HStack {
                Text("動作確認")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                
                Button(action: onTestShortcut) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("テスト実行")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.blue.opacity(0.2)))
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Command Section
    
    private var commandSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("💻 実行コマンド")
                    .font(.headline)
                    .frame(width: 200, alignment: .leading)

                TextField("例: open -a Safari", text: $commandString)
                    .font(.system(size: 13, weight: .medium))
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 8)
                    .frame(width: 200, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.white.opacity(0.1))
                            .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                    )
                    .onSubmit { onSaveCommand() }
                    .onChange(of: commandString) { _, _ in onSaveCommand() }
            }
        }
    }
}
