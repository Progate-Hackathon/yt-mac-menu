import SwiftUI

struct TutorialStep4View: View {
    let onNext: () -> Void       // 次へ進むハンドラ
    let onSkip: () -> Void       // チュートリアルをスキップするハンドラ

    var body: some View {
        VStack(spacing: 32) {
            Text("カメラプレビューの説明")
                .font(.title)
                .bold()

            Text("""
                カメラプレビュー画面が表示されます。
                手を見せる位置を調整し、カメラ映像を確認しましょう。

                ジェスチャーを検知するにはまず最初に手を２個検知する必要があります。
                """)
                .font(.body)
                .multilineTextAlignment(.leading)
                .padding(.horizontal)
            
            HStack(spacing: 24) {
                Button("スキップ", action: onSkip)
                    .buttonStyle(.bordered)
                Button("次へ", action: onNext)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
