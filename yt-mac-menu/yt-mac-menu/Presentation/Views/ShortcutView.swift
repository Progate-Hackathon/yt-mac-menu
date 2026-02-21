import SwiftUI

struct ShortcutView: View {
    @StateObject private var viewModel = ShortcutViewModel()
    @State private var showRecorderPopover = false
    @State private var showPeaceRecorderPopover = false
    @State private var showThumbsUpRecorderPopover = false
    @State private var showSnapTriggerPopover = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // セクション: snap検知トリガーショートカット
            snapTriggerSection
            
            Divider()
            
            // セクション: ハートジェスチャーアクション
            GestureActionSection(
                gestureName: "ハート検出時のアクション",
                gestureEmoji: "🫶",
                actionType: $viewModel.actionType,
                hotkey: $viewModel.currentHotkey,
                commandString: $viewModel.commandString,
                showRecorderPopover: $showRecorderPopover,
                showSuccess: $viewModel.showSuccess,
                tempModifiers: $viewModel.tempModifiers,
                tempKeyDisplay: $viewModel.tempKeyDisplay,
                onActionTypeChange: { viewModel.saveActionType($0) },
                onSaveCommand: { viewModel.saveCommand() },
                onStartRecording: {
                    showRecorderPopover = true
                    viewModel.onRecordingComplete = { showRecorderPopover = false }
                    viewModel.startRecording(for: .heart)
                },
                onStopRecording: { viewModel.stopRecording() },
                onTestShortcut: { viewModel.runTestShortcut() }
            )
            
            Divider()
            
            // セクション: ピースジェスチャーアクション
            GestureActionSection(
                gestureName: "ピース検出時のアクション",
                gestureEmoji: "✌️",
                actionType: $viewModel.peaceActionType,
                hotkey: $viewModel.peaceHotkey,
                commandString: $viewModel.peaceCommandString,
                showRecorderPopover: $showPeaceRecorderPopover,
                showSuccess: $viewModel.showSuccess,
                tempModifiers: $viewModel.tempModifiers,
                tempKeyDisplay: $viewModel.tempKeyDisplay,
                onActionTypeChange: { viewModel.savePeaceActionType($0) },
                onSaveCommand: { viewModel.savePeaceCommand() },
                onStartRecording: {
                    showPeaceRecorderPopover = true
                    viewModel.onRecordingComplete = { showPeaceRecorderPopover = false }
                    viewModel.startRecording(for: .peace)
                },
                onStopRecording: { viewModel.stopRecording() },
                onTestShortcut: {
                    KeySender.activatePreviousAppAndSimulateShortcut(
                        keyCode: viewModel.peaceHotkey.keyCode,
                        modifiers: viewModel.peaceHotkey.modifiers
                    )
                }
            )
            
            Divider()
            
            // セクション: サムズアップジェスチャーアクション
            GestureActionSection(
                gestureName: "サムズアップ検出時のアクション",
                gestureEmoji: "👍",
                actionType: $viewModel.thumbsUpActionType,
                hotkey: $viewModel.thumbsUpHotkey,
                commandString: $viewModel.thumbsUpCommandString,
                showRecorderPopover: $showThumbsUpRecorderPopover,
                showSuccess: $viewModel.showSuccess,
                tempModifiers: $viewModel.tempModifiers,
                tempKeyDisplay: $viewModel.tempKeyDisplay,
                onActionTypeChange: { viewModel.saveThumbsUpActionType($0) },
                onSaveCommand: { viewModel.saveThumbsUpCommand() },
                onStartRecording: {
                    showThumbsUpRecorderPopover = true
                    viewModel.onRecordingComplete = { showThumbsUpRecorderPopover = false }
                    viewModel.startRecording(for: .thumbsUp)
                },
                onStopRecording: { viewModel.stopRecording() },
                onTestShortcut: {
                    KeySender.activatePreviousAppAndSimulateShortcut(
                        keyCode: viewModel.thumbsUpHotkey.keyCode,
                        modifiers: viewModel.thumbsUpHotkey.modifiers
                    )
                }
            )
        }
    }
    // MARK: - Snap Trigger Section
    
    private var snapTriggerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("👆 スナップを検知する (ON/OFF)")
                    .font(.headline)
                    .frame(width: 200, alignment: .leading)

                Button(action: {
                    showSnapTriggerPopover = true
                    viewModel.onSnapRecordingComplete = {
                        showSnapTriggerPopover = false
                    }
                    viewModel.startRecordingSnapTrigger()
                }) {
                    Text(viewModel.snapTriggerHotkey?.displayString ?? "未設定（クリックして設定）")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(viewModel.snapTriggerHotkey == nil ? .secondary : .white)
                        .frame(width: 200, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.white.opacity(0.1))
                                .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                        )
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showSnapTriggerPopover, arrowEdge: .top) {
                    RecorderOverlaySectionView(
                        showSuccess: $viewModel.showSnapTriggerSuccess,
                        tempModifiers: $viewModel.tempSnapModifiers,
                        tempKeyDisplay: $viewModel.tempSnapKeyDisplay,
                        currentHotkey: $viewModel.snapTriggerPreviewHotkey,
                        stopRecording: viewModel.stopRecordingSnapTrigger
                    )
                }
            }

            if let error = viewModel.showSnapTriggerError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }
}

// MARK: - Preview
struct ShortcutView_Previews: PreviewProvider {
    static var previews: some View {
        ShortcutView()
            .preferredColorScheme(.dark)
    }
}
