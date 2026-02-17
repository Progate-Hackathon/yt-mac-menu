//
//  TutorialWindowRootView.swift
//  yt-mac-menu
//
//  Created by cmStudent on 2026/02/17.
//

import SwiftUI

struct TutorialWindowRootView: View {
    @ObservedObject var tutorialVM: TutorialViewModel

    var body: some View {
        Group {
            switch tutorialVM.step {
            case .step1_settingsIntro:
                TutorialStep1View(
                    onNext: { tutorialVM.nextStep() },
                    onSkip: { tutorialVM.skipTutorial() }
                )
            case .step2_pathAndToken:
                TutorialStep2View(
                    onNext: { tutorialVM.nextStep() },
                    onSkip: { tutorialVM.skipTutorial() }
                )
            case .step3_fingerSnap:
                TutorialStep3View(
                    onNext: { tutorialVM.nextStep() },
                    onSkip: { tutorialVM.skipTutorial() }
                )
            case .step4_camera:
                TutorialStep4View(
                    onNext: { tutorialVM.nextStep() },
                    onSkip: { tutorialVM.skipTutorial() }
                )
            case .step5_gesture:
                TutorialStep5View(
                    onFinish: { tutorialVM.nextStep() },
                    onSkip: { tutorialVM.skipTutorial() }
                )
            case .end:
                EmptyView() // 表示しない
            }
        }
        .frame(width: 500, height: 360)
        .background(Color(.windowBackgroundColor))
    }
}

