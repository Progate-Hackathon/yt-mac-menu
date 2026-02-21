import Foundation

struct GitResult {
    let stdout: String
    let stderr: String
    let exitCode: Int32

    var isSuccess: Bool { exitCode == 0 }
}

/// Git コマンドを直接実行するユーティリティ
/// ShellExecutor と異なり、シェルを経由せず /usr/bin/git を直接呼び出すため、
/// 特殊文字 (括弧、パイプ等) がシェルパースされない
enum GitExecutor {
    /// Git コマンドを同期実行する（呼び出しスレッドをブロック）
    ///
    /// - Parameters:
    ///   - arguments: Git コマンドの引数配列（例: ["branch", "--format=%(refname:short)"]）
    ///   - workingDirectory: コマンド実行ディレクトリ
    /// - Returns: コマンドの実行結果
    static func executeSync(arguments: [String], at workingDirectory: String? = nil) -> GitResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = arguments
        
        if let dir = workingDirectory {
            process.currentDirectoryURL = URL(fileURLWithPath: dir)
        }

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return GitResult(stdout: "", stderr: error.localizedDescription, exitCode: -1)
        }

        let stdout = String(
            data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        )?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let stderr = String(
            data: stderrPipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        )?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        return GitResult(stdout: stdout, stderr: stderr, exitCode: process.terminationStatus)
    }

    /// Git コマンドを非同期実行する
    ///
    /// - Parameters:
    ///   - arguments: Git コマンドの引数配列
    ///   - workingDirectory: コマンド実行ディレクトリ
    /// - Returns: コマンドの実行結果
    static func execute(arguments: [String], at workingDirectory: String? = nil) async -> GitResult {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                continuation.resume(returning: executeSync(arguments: arguments, at: workingDirectory))
            }
        }
    }
}
