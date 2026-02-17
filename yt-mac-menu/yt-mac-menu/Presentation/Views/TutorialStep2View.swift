//
//  TutorialStep3View.swift
//  yt-mac-menu
//
//  Created by cmStudent on 2026/02/17.
//

import SwiftUI

struct TutorialStep2View: View {
    let onNext: () -> Void       // 次へ進むハンドラ
    let onSkip: () -> Void       // チュートリアルをスキップするハンドラ

    var body: some View {
        VStack(spacing: 32) {
            Text("初期設定をしましょう")
                .font(.title)
                .bold()

            Text("""
                使用するにはまず初めに以下の設定が必要です。
                
                ・プロジェクトのパスの設定。
                ・GitHubアクセストークンの設定。

                これらの設定を済ませることで、ショートカットが利用できます。
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
