//
//  OnboardView.swift
//  yt-mac-menu
//
//  Created by cmStudent on 2026/02/21.
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var onboardViewMoel: OnboardViewModel
    
    @State private var step = 0
    
    let maxStep = 3 // 最後のステップ数を定義しておくと管理が楽です

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // メインコンテンツ部分
            Group {
                switch step {
                case 0:
                    Step1View()
                case 1:
                    Step2View()
                case 2:
                    Step3View(
                        selectedProjectPath: $onboardViewMoel.selectedProjectPath,
                        githubToken: $onboardViewMoel.githubToken,
                        baseBranch: $onboardViewMoel.baseBranch,
                        shouldCreatePR: $onboardViewMoel.shouldCreatePR,
                        hasUnsavedChanges: $onboardViewMoel.hasUnsavedChanges,
                        errorMessage: $onboardViewMoel.errorMessage,
                        isSaving: $onboardViewMoel.isSaving,
                        settingsSaved: $onboardViewMoel.settingsSaved,
                        saveSettinss: $onboardViewMoel.saveSettinss
                        
                    )
                case 3:
                    Step4View()
                default:
                    // 範囲外の値が来た場合のフォールバック
                    Step1View()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

            // 下部ナビゲーション部分
            HStack {
                // 左: 戻る（step > 0 のときのみ表示）
                if step > 0 {
                    Button("戻る") {
                        withAnimation { step -= 1 }
                    }
                }

                Spacer() // これがあることで、左のボタンは左寄せ、右のボタンは右寄せになります

                // 右: 次へ or 完了
                if step < maxStep {
                    Button("次へ") {
                        withAnimation { step += 1 }
                    }
                    .keyboardShortcut(.defaultAction) // Enterキーで進めるようにする
                } else {
                    // 最後の画面ではボタンのテキストを「完了」などに変えるのがおすすめです
                    Button("完了してはじめる") {
                        // TODO: ウィンドウを閉じる、またはメイン画面へ遷移する処理
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
        .padding()
        }
}

#Preview {
    OnboardingView()
}
