import Foundation

enum CommitError: LocalizedError {
    case invalidConfiguration(String)
    case requestCreationError(Error)
    case networkError(Error)
    case serverError(message: String, status: Int, upstreamMessage: String?)
    case invalidResponse
    case decodingError(Error)
    
    
    var errorDescription: String? {
        switch self {
        case .invalidConfiguration(let detail):
            return "アプリの設定エラー: \(detail)"
        case .requestCreationError:
            return "リクエストの作成に失敗しました。"
        case .networkError(let error):
            return "通信エラー: \(error.localizedDescription)"
        case .serverError(let message, let status, _):
            return "サーバーエラー (\(status)): \(message)"
        case .invalidResponse:
            return "サーバーから無効な応答が返ってきました。"
        case .decodingError:
            return "データの処理に失敗しました。"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .invalidConfiguration:
            return "Info.plistの設定を確認してください。"
        case .networkError:
            return "インターネット接続を確認してください。"
        case .serverError(_, let status, let upstream):
            if let upstream = upstream { return "詳細: \(upstream)" }
            return status == 401 ? "認証トークンを確認してください。" : "入力内容を確認して再試行してください。"
        default:
            return "時間を置いて再度お試しいただくか、開発者へお問い合わせください。"
        }
    }
}
