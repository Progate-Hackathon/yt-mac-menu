//
//  TutorialStep1View.swift
//  yt-mac-menu
//
//  Created by cmStudent on 2026/02/17.
//

import SwiftUI

struct TutorialStep1View: View {
    let onNext: () -> Void       // 次へ進むハンドラ
    let onSkip: () -> Void       // チュートリアルをスキップするハンドラ

    var body: some View {
        VStack(spacing: 32) {
            Text("ようこそ！")
                .font(.largeTitle)
                .bold()

            Text("まずは画面上部のメニューバーから★のアイコンをクリックして「Settings」を開きましょう。")
                .font(.body)
                .multilineTextAlignment(.center)
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
