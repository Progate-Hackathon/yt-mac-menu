import SwiftUI

struct ShortcutView: View {
    @StateObject private var viewModel = ShortcutViewModel()
    @State private var showRecorderPopover = false
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 20) {
                
                // セクション: アクションタイプ選択
                VStack(alignment: .leading, spacing: 8) {
                    Text("ハート検出時のアクション")
                        .font(.headline)
                    
                    Picker("", selection: $viewModel.actionType) {
                        ForEach(ActionType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: 200)
                    .onChange(of: viewModel.actionType) { _, newValue in
                        viewModel.saveActionType(newValue)
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
                            
                            Button(action: {
                                showRecorderPopover = true
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
                                    isRecording: $viewModel.isRecording,
                                    isSuccessState: $viewModel.isSuccessState,
                                    tempModifiers: $viewModel.tempModifiers,
                                    tempKeyDisplay: $viewModel.tempKeyDisplay,
                                    currentHotkey: viewModel.currentHotkey,
                                    isPresented: $showRecorderPopover,
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
            }
            .padding(40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview
struct ShortcutView_Previews: PreviewProvider {
    static var previews: some View {
        ShortcutView()
            .preferredColorScheme(.dark)
    }
}
