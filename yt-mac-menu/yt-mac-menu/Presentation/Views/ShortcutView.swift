import SwiftUI

struct ShortcutView: View {
    @StateObject private var viewModel = ShortcutViewModel()
    @State private var showRecorderPopover = false
    @State private var showSnapTriggerPopover = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // セクション: snap検知トリガーショートカット
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

            Divider()

            // セクション: アクションタイプ選択
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("ハート検出時のアクション")
                        .font(.headline)
                        .frame(width: 200, alignment: .leading)

                    Picker("", selection: $viewModel.actionType) {
                        ForEach(ActionType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 200)
                    .onChange(of: viewModel.actionType) { _, newValue in
                        viewModel.saveActionType(newValue)
                    }
                }

                Text(viewModel.actionType.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            if viewModel.actionType == .shortcut {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("🫶 ショートカットキー")
                            .font(.headline)
                            .frame(width: 200, alignment: .leading)
                        
                        Button(action: {
                            showRecorderPopover = true
                            viewModel.onRecordingComplete = {
                                showRecorderPopover = false
                            }
                            viewModel.startRecording()
                        }) {
                            Text(viewModel.currentHotkey.displayString)
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
                                showSuccess: $viewModel.showSuccess,
                                tempModifiers: $viewModel.tempModifiers,
                                tempKeyDisplay: $viewModel.tempKeyDisplay,
                                currentHotkey: $viewModel.currentHotkey,
                                stopRecording: viewModel.stopRecording
                            )
                        }
                    }
                    
                    // セクション: 動作テスト
                    HStack {
                        Text("動作確認")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                        
                        Button(action: {
                            viewModel.runTestShortcut()
                        }) {
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

            if viewModel.actionType == .command {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("💻 実行コマンド")
                            .font(.headline)
                            .frame(width: 200, alignment: .leading)

                        TextField("例: open -a Safari", text: $viewModel.commandString)
                            .font(.system(size: 13, weight: .medium))
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 8)
                            .frame(width: 200, height: 32)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(.white.opacity(0.1))
                                    .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                            )
                            .onSubmit { viewModel.saveCommand() }
                            .onChange(of: viewModel.commandString) { _, _ in viewModel.saveCommand() }
                    }
                }
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
