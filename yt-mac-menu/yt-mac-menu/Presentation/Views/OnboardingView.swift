import SwiftUI

struct OnboardingView: View {
    @StateObject private var vm = OnboardingViewModel()
    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // ステップインジケーター
            HStack(spacing: 6) {
                ForEach(0..<vm.totalSteps, id: \.self) { i in
                    Circle()
                        .fill(i == vm.currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 7, height: 7)
                }
            }
            .padding(.top, 20)

            // コンテンツ
            ZStack {
                switch vm.currentStep {
                case 0: step0Welcome
                case 1: step1GitHub
                case 2: step2SnapTrigger
                case 3: step3SnapCalibration
                case 4: step4HeartAction
                case 5: step5Done
                default: EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 32)

            // ナビゲーションボタン
            HStack {
                if vm.currentStep > 0 && vm.currentStep < vm.totalSteps - 1 && vm.currentStep != 3 {
                    Button("戻る") { vm.back() }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 20)
        }
        .frame(width: 480, height: 380)
        .background(.ultraThinMaterial)
    }

    // MARK: - Step 0: ようこそ

    private var step0Welcome: some View {
        VStack(spacing: 20) {
            Image(systemName: "hand.wave.fill")
                .font(.system(size: 52))
                .foregroundStyle(.yellow)
            Text("yt-mac-menu へようこそ")
                .font(.title2).bold()
            Text("スナップやハートジェスチャーで\nGitHubコミット・ショートカット・コマンドを実行できるメニューバーアプリです。\n\n初期設定を行いましょう。")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("始める") { vm.next() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding(.vertical, 24)
    }

    // MARK: - Step 1: GitHub設定

    private var step1GitHub: some View {
        VStack(alignment: .leading, spacing: 8) {
            stepHeader(icon: "lock.fill", title: "GitHub設定", subtitle: "コミット機能を使うにはGitHubトークンとプロジェクトパスが必要です")

            ProjectPathSectionView(selectedProjectPath: $vm.projectPath)
            GitHubTokenSectionView(gitHubAccessToken: $vm.githubToken)

            if let err = vm.step2Error {
                Text(err).font(.caption).foregroundStyle(.red).padding(.horizontal)
            }

            HStack {
                Spacer()
                Button(vm.isValidating ? "検証中..." : "次へ") {
                    Task {
                        if await vm.validateAndSaveGitHub() { vm.next() }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(vm.isValidating)

                Button("スキップ") { vm.next() }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }

    // MARK: - Step 2: スナップ検知トリガー

    @State private var showSnapPopover = false
    @State private var showHeartPopover = false

    private var step2SnapTrigger: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepHeader(icon: "hand.point.up.fill", title: "スナップ検知トリガー", subtitle: "スナップ検知をON/OFFするショートカットキーを設定します")

            HStack {
                Text("👆 スナップを検知する (ON/OFF)")
                    .font(.headline)
                    .frame(width: 200, alignment: .leading)

                Button {
                    showSnapPopover = true
                    vm.onSnapRecordingComplete = { showSnapPopover = false }
                    vm.startRecordingSnap()
                } label: {
                    Text(vm.snapTriggerHotkey?.displayString ?? "未設定（クリックして設定）")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(vm.snapTriggerHotkey == nil ? .secondary : .white)
                        .frame(width: 200, height: 32)
                        .background(RoundedRectangle(cornerRadius: 6).fill(.white.opacity(0.1)).shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1))
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showSnapPopover, arrowEdge: .top) {
                    RecorderOverlaySectionView(
                        showSuccess: $vm.showSnapSuccess,
                        tempModifiers: $vm.tempSnapModifiers,
                        tempKeyDisplay: $vm.tempSnapKeyDisplay,
                        currentHotkey: $vm.snapPreviewHotkey,
                        stopRecording: vm.stopRecordingSnap
                    )
                }
            }

            if let err = vm.snapTriggerError {
                Label(err, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Spacer()

            HStack {
                Spacer()
                Button("次へ") { vm.stopRecordingSnap(); showSnapPopover = false; vm.next() }
                    .buttonStyle(.borderedProminent)
                    .disabled(vm.snapTriggerHotkey == nil)
            }
        }
    }

    // MARK: - Step 3: スナップキャリブレーション

    private var step3SnapCalibration: some View {
        VStack(spacing: 24) {
            stepHeader(icon: "waveform.circle.fill", title: "スナップ音キャリブレーション", subtitle: "あなたの指パッチン音を学習します。\(vm.calibrationTarget)回パッチンを鳴らしてください")

            if vm.calibrationCompleted {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.green)
                    Text("プロファイルを作成しました！")
                        .font(.title2).bold()
                    Text("これであなたのスナップ音に最適化されました。")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "hand.point.up.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.yellow)
                        .symbolEffect(.bounce, options: .repeating)
                    Text("\(vm.calibrationCollected) / \(vm.calibrationTarget)")
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                    ProgressView(value: Double(vm.calibrationCollected), total: Double(vm.calibrationTarget))
                        .progressViewStyle(.linear)
                        .frame(maxWidth: 260)
                    if !vm.isCalibrating {
                        Text("キャリブレーションを開始しています...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("👆 指パッチンを鳴らしてください")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            HStack {
                Spacer()
                Button("次へ") { vm.stopCalibrationSubscription(); vm.next() }
                    .buttonStyle(.borderedProminent)
                    .disabled(!vm.calibrationCompleted)
            }
        }
        .onAppear {
            if !vm.calibrationCompleted {
                vm.startCalibration()
            }
        }
        .onDisappear { vm.stopCalibrationSubscription() }
    }

    // MARK: - Step 4: ハートアクション

    private var step4HeartAction: some View {
        VStack(alignment: .leading, spacing: 14) {
            stepHeader(icon: "heart.fill", title: "ハート検出アクション", subtitle: "🫶ジェスチャーを検出したときの動作を設定します")

            HStack {
                Text("アクション")
                    .font(.subheadline).bold()
                    .frame(width: 120, alignment: .leading)
                Picker("", selection: $vm.actionType) {
                    ForEach(ActionType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(width: 200)
                .onChange(of: vm.actionType) { _, newValue in vm.saveActionType(newValue) }
            }

            if vm.actionType == .shortcut {
                HStack {
                    Text("ショートカットキー")
                        .font(.headline)
                        .frame(width: 200, alignment: .leading)
                    Button {
                        showHeartPopover = true
                        vm.onHeartRecordingComplete = { showHeartPopover = false }
                        vm.startRecordingHeart()
                    } label: {
                        Text(vm.heartHotkey?.displayString ?? "未設定（クリックして設定）")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(vm.heartHotkey == nil ? .secondary : .white)
                            .frame(width: 200, height: 32)
                            .background(RoundedRectangle(cornerRadius: 6).fill(.white.opacity(0.1)).shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1))
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showHeartPopover, arrowEdge: .top) {
                        RecorderOverlaySectionView(
                            showSuccess: $vm.showHeartSuccess,
                            tempModifiers: $vm.tempHeartModifiers,
                            tempKeyDisplay: $vm.tempHeartKeyDisplay,
                            currentHotkey: $vm.heartPreviewHotkey,
                            stopRecording: vm.stopRecordingHeart
                        )
                    }
                }
            }

            if vm.actionType == .command {
                HStack {
                    Text("コマンド")
                        .font(.subheadline).bold()
                        .frame(width: 120, alignment: .leading)
                    TextField("例: open -a Safari", text: $vm.commandString)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 8)
                        .frame(width: 200, height: 32)
                        .background(RoundedRectangle(cornerRadius: 6).fill(.white.opacity(0.1)))
                        .onSubmit { vm.saveCommand() }
                        .onChange(of: vm.commandString) { _, _ in vm.saveCommand() }
                }
            }

            if vm.actionType == .commit && (vm.githubToken.isEmpty || vm.projectPath.isEmpty) {
                Label("コミットを使うには前のステップでGitHub設定が必要です", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            Spacer()

            HStack {
                Spacer()
                Button("次へ") { vm.stopRecordingHeart(); showHeartPopover = false; vm.next() }
                    .buttonStyle(.borderedProminent)
                    .disabled({
                        switch vm.actionType {
                        case .shortcut: return vm.heartHotkey == nil
                        case .command: return vm.commandString.trimmingCharacters(in: .whitespaces).isEmpty
                        case .commit: return vm.githubToken.isEmpty || vm.projectPath.isEmpty
                        }
                    }())
            }
        }
    }

    // MARK: - Step 5: 完了

    private var step5Done: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 52))
                .foregroundStyle(.green)
            Text("設定完了！")
                .font(.title2).bold()
            Text("設定はいつでも\nメニューバー → 設定 から変更できます。")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("始める") {
                vm.complete()
                onComplete()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(.vertical, 24)
    }

    // MARK: - Helpers

    private func stepHeader(icon: String, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.title3).bold()
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

}
