import SwiftUI

struct GestureDetectionView: View {
    @StateObject private var gestureDetectionViewModel = GestureDetectionViewModel()
    
    var body: some View {
        ZStack {
            switch gestureDetectionViewModel.appState {
            case .detecting:
                DetectingStateView()
            case .success:
                StatusFeedbackSectionView(
                    title: "送信完了しました",
                    subtitle: "3秒後に閉じます...",
                    iconName: "checkmark.circle.fill",
                    color: .green
                )
            case .waiting:
                StatusFeedbackSectionView(
                    title: "読み込み中です",
                    subtitle: "しばらくお待ちください...",
                    iconName: "hourglass",
                    color: .gray
                )
            case .unauthorized:
                VStack {
                    Image(systemName: "video.slash")
                        .font(.largeTitle)
                    Text("カメラの権限が必要です")
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
    }
}


struct DetectingStateView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.2), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: 0.25)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
            }
            .onAppear { isAnimating = true }
            
            Text("ジェスチャーを検知中...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            Text("カメラに向かって🫶ジェスチャーをしてください")
                .font(.system(size: 11))
                .foregroundColor(.gray)
        }
    }
}


