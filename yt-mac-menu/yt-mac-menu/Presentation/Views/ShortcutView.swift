import SwiftUI

struct ShortcutView: View {
    @StateObject private var viewModel = ShortcutViewModel()
    @State private var showSnapTriggerPopover = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // セクション: snap検知トリガーショートカット
                snapTriggerSection
                
                Divider()
                
                // セクション: ハートジェスチャーアクション
                GestureActionSection(gestureType: .heart, viewModel: viewModel)
                
                Divider()
                
                // セクション: ピースジェスチャーアクション
                GestureActionSection(gestureType: .peace, viewModel: viewModel)
                
                Divider()
                
                // セクション: サムズアップジェスチャーアクション
                GestureActionSection(gestureType: .thumbsUp, viewModel: viewModel)
            }
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
