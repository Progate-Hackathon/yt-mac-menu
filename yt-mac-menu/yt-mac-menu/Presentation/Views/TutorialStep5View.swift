import SwiftUI

struct TutorialStep5View: View {
    let onFinish: () -> Void     // チュートリアル終了ハンドラ
    let onSkip: () -> Void       // チュートリアルをスキップするハンドラ

    var body: some View {
        VStack(spacing: 32) {
            Text("ジェスチャー一覧と使い方")
                .font(.title)
                .bold()

            Text("""
                このアプリでは以下のジェスチャー操作が利用できます:

                ・♡ハートマーク: GitComit＆Push

                yt-mac-menuを使いこなして、開発をより豊かにしていきましょう!

                """)
                .font(.body)
                .multilineTextAlignment(.leading)
                .padding(.horizontal)

            HStack(spacing: 24) {
                Button("スキップ", action: onSkip)
                    .buttonStyle(.bordered)
                Button("始める！", action: onFinish)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
