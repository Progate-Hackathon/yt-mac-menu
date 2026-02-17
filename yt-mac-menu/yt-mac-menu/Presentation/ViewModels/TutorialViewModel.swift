//
//  TutorialViewModel.swift
//  yt-mac-menu
//
//  Created by cmStudent on 2026/02/17.
//
import SwiftUI
import Combine

// チュートリアルの各ステップをenumで定義
enum TutorialStep: Int, CaseIterable, Identifiable {
    case step1_settingsIntro    // メニューバーからSettings説明
    case step2_pathAndToken    // パス・トークン入力説明
    case step3_fingerSnap      // 指パッチン説明
    case step4_camera          // カメラ（プレビュー）説明
    case step5_gesture         // ジェスチャー説明
    case end                   // 終了

    var id: Int { rawValue }
}

// ViewModel本体
class TutorialViewModel: ObservableObject {
    // 現在のステップ
    @Published var step: TutorialStep = .step1_settingsIntro

    // 初回だけ判定（2回目以降チュートリアルを自動スキップ）
    @AppStorage("hasSeenTutorial") var hasSeenTutorial: Bool = false

    // 完了判定
    var isCompleted: Bool {
        step == .end
    }

    // 進行操作
    func nextStep() {
        if let next = TutorialStep(rawValue: step.rawValue + 1) {
            step = next
        } else {
            finish()
        }
    }

    func skipTutorial() {
        finish()
    }

    private func finish() {
        step = .end
        hasSeenTutorial = true
    }

    // 初回起動時に呼ぶ。既読ならstep=endで表示しない
    func startIfNeeded() {
        if !hasSeenTutorial {
            step = .step1_settingsIntro
        } else {
            step = .end
        }
    }
}
