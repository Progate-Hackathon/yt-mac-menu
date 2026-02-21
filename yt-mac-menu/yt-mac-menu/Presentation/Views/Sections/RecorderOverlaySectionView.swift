import SwiftUI

struct RecorderOverlaySectionView: View {
    @Binding var showSuccess: Bool
    @Binding var tempModifiers: NSEvent.ModifierFlags
    @Binding var tempKeyDisplay: String
    @Binding var currentHotkey: Hotkey
    let stopRecording: () -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .frame(width: 260, height: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(showSuccess ? Color.green : Color.clear, lineWidth: 2)
                )
            
            VStack(spacing: 8) {
                if showSuccess {
                    successView
                } else {
                    recordingView
                }
            }
        }
        .onDisappear {
            stopRecording()
        }
    }
    
    // MARK: - Subviews
    
    private var successView: some View {
        VStack(spacing: 8) {
            Text(currentHotkey.displayString)
                .font(.system(size: 16, weight: .bold))
                .padding(4)
                .background(Color.green.opacity(0.2))
                .cornerRadius(4)
                .foregroundColor(.green)
            Text("新しいショートカットが設定されました！")
                .font(.caption)
                .foregroundColor(.white)
        }
    }
    
    private var recordingView: some View {
        VStack(spacing: 5) {
            HStack(spacing: 4) {
                if tempModifiers.isEmpty && tempKeyDisplay.isEmpty {
                    Text("記録中...")
                        .foregroundColor(.gray)
                } else {
                    Text(tempModifiers.formattedString)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    if !tempKeyDisplay.isEmpty {
                        Text(tempKeyDisplay)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            
            if tempModifiers.isEmpty && tempKeyDisplay.isEmpty {
                Text("キーを押してショートカットを設定")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
