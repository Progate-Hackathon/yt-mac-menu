//
//  ActionError.swift
//  yt-mac-menu
//
//  Created by cmStudent on 2026/02/21.
//

import Foundation

/// アクション実行時のエラー
enum ActionError: LocalizedError {
    case accessibilityPermissionDenied
    case cameraPermissionDenied
    case hotkeyNotConfigured
    case commandNotConfigured
    case commandFailed(exitCode: Int32, stderr: String)
    
    var errorDescription: String? {
        switch self {
        case .accessibilityPermissionDenied:
            return "アクセシビリティの権限が必要です"
        case .cameraPermissionDenied:
            return "カメラの権限が必要です"
        case .hotkeyNotConfigured:
            return "ショートカットキーが設定されていません"
        case .commandNotConfigured:
            return "コマンドが設定されていません"
        case .commandFailed(let exitCode, let stderr):
            return stderr.isEmpty ? "コマンドが失敗しました (exit \(exitCode))" : stderr
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .accessibilityPermissionDenied:
            return "システム設定 > プライバシーとセキュリティ > アクセシビリティ で許可してください"
        case .cameraPermissionDenied:
            return "システム設定 > プライバシーとセキュリティ > カメラ で許可してください"
        case .hotkeyNotConfigured:
            return "設定画面でショートカットキーを登録してください"
        case .commandNotConfigured:
            return "設定画面でコマンドを入力してください"
        case .commandFailed:
            return nil
        }
    }
    
    /// システム設定を開くURL（該当する場合）
    var systemSettingsURL: URL? {
        switch self {
        case .accessibilityPermissionDenied:
            return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
        case .cameraPermissionDenied:
            return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera")
        default:
            return nil
        }
    }
}
