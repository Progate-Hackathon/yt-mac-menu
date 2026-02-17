import SwiftUI

struct TutorialStep3View: View {
    let onNext: () -> Void       // 次へ進むハンドラ
    let onSkip: () -> Void       // チュートリアルをスキップするハンドラ

    var body: some View {
        VStack(spacing: 32) {
            Text("指パッチンでカメラ起動！")
                .font(.title)
                .bold()

            Text("""
                設定が完了したら、「指パッチン」をしてみましょう。

                AIが指パッチンの音を検知し、自動でカメラを起動します。
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
