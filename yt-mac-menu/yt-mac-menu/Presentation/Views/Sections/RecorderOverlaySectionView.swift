import SwiftUI

struct RecorderOverlaySectionView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .frame(width: 260, height: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(viewModel.isSuccessState ? Color.green : Color.clear, lineWidth: 2)
                )
            
            VStack(spacing: 8) {
                if viewModel.isSuccessState {
                    successView
                } else {
                    recordingView
                }
            }
        }
        .onChange(of: viewModel.isRecording) { _, isRecording in
            if !isRecording {
                isPresented = false
            }
        }
        .onDisappear {
            viewModel.stopRecording()
        }
    }
    
    // MARK: - Subviews
    
    private var successView: some View {
        VStack(spacing: 8) {
            HStack {
                Text(KeySender.formatModifiers(viewModel.currentHotkey.modifiers) + viewModel.currentHotkey.keyDisplay)
                    .font(.system(size: 16, weight: .bold))
                    .padding(4)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(4)
                    .foregroundColor(.green)
                
                // レイアウト崩れ防止の不可視要素
                Text("Space").hidden()
            }
            Text("新しいショートカットが設定されました！")
                .font(.caption)
                .foregroundColor(.white)
        }
    }
    
    private var recordingView: some View {
        VStack(spacing: 5) {
            HStack(spacing: 4) {
                if viewModel.tempModifiers.isEmpty && viewModel.tempKeyDisplay.isEmpty {
                    Text("記録中...")
                        .foregroundColor(.gray)
                } else {
                    Text(KeySender.formatModifiers(viewModel.tempModifiers))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    if !viewModel.tempKeyDisplay.isEmpty {
                        Text(viewModel.tempKeyDisplay)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            
            if viewModel.tempModifiers.isEmpty && viewModel.tempKeyDisplay.isEmpty {
                Text("キーを押してショートカットを設定")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
