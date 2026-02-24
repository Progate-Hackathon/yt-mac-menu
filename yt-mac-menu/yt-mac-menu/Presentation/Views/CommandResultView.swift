import SwiftUI

struct CommandResultView: View {
    let result: ShellResult
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            // ヘッダー
            HStack(spacing: 6) {
                Image(systemName: result.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.body)
                    .foregroundColor(result.isSuccess ? .green : .red)
                Text(result.isSuccess ? "コマンド成功" : "コマンド失敗 (exit \(result.exitCode))")
                    .font(.subheadline).bold()
                Spacer()
            }

            Divider()

            // stdout
            if !result.stdout.isEmpty {
                ScrollView {
                    Text(result.stdout)
                        .font(.system(.caption2, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(maxHeight: 80)
                .padding(4)
                .background(RoundedRectangle(cornerRadius: 4).fill(.black.opacity(0.2)))
            }

            // stderr
            if !result.stderr.isEmpty {
                ScrollView {
                    Text(result.stderr)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.red.opacity(0.9))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(maxHeight: 60)
                .padding(4)
                .background(RoundedRectangle(cornerRadius: 4).fill(.black.opacity(0.2)))
            }

            if result.stdout.isEmpty && result.stderr.isEmpty {
                Text("出力なし")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
        .background(GeometryReader { geo in
            Color.clear.preference(key: WindowSizeKey.self, value: CGSize(width: 320, height: geo.size.height))
        })
    }
}
