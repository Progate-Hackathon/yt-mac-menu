//
//  ErrorStateView.swift
//  yt-mac-menu
//
//  Created by アウン on 2026/02/15.
//

import SwiftUI

struct ErrorStateView: View {
    let error: Error
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            // アイコンとタイトル
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(errorColor.opacity(0.15))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: errorIcon)
                        .font(.system(size: 40))
                        .foregroundColor(errorColor)
                }
                
                Text(errorTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            // エラーの詳細
            VStack(spacing: 12) {
                if let localizedError = error as? LocalizedError {
                    if let errorDescription = localizedError.errorDescription {
                        Text(errorDescription)
                            .font(.body)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                    }
                    
                    if let recoverySuggestion = localizedError.recoverySuggestion {
                        HStack(spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            
                            Text(recoverySuggestion)
                                .font(.callout)
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .background(Color.yellow.opacity(0.1))
                        .cornerRadius(8)
                    }
                } else {
                    Text(error.localizedDescription)
                        .font(.body)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                }
                
                // 技術的な詳細（折りたたみ可能）
                if shouldShowTechnicalDetails {
                    DisclosureGroup {
                        Text(error.localizedDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(6)
                    } label: {
                        HStack {
                            Image(systemName: "info.circle")
                                .font(.caption)
                            Text("技術的な詳細")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal, 32)
            
            // アクションボタン
            VStack(spacing: 12) {
                primaryActionButton
                
                Button(action: {
                    dismiss()
                }) {
                    Text("閉じる")
                        .font(.body)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 32)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: 400)
    }
    
    // MARK: - Computed Properties
    
    private var errorTitle: String {
        if error is GitHubTokenError {
            return "認証エラー"
        } else if error is GitError {
            return "Git操作エラー"
        } else if let commitError = error as? CommitError {
            switch commitError {
            case .networkError:
                return "接続エラー"
            case .serverError:
                return "サーバーエラー"
            default:
                return "エラーが発生しました"
            }
        } else {
            return "エラーが発生しました"
        }
    }
    
    private var errorIcon: String {
        if error is GitHubTokenError {
            return "key.slash"
        } else if error is GitError {
            return "arrow.triangle.branch"
        } else if let commitError = error as? CommitError {
            switch commitError {
            case .networkError:
                return "wifi.exclamationmark"
            case .serverError:
                return "server.rack"
            default:
                return "exclamationmark.triangle.fill"
            }
        } else {
            return "exclamationmark.triangle.fill"
        }
    }
    
    private var errorColor: Color {
        if error is GitHubTokenError {
            return .orange
        } else if let commitError = error as? CommitError {
            switch commitError {
            case .networkError:
                return .blue
            default:
                return .red
            }
        } else {
            return .red
        }
    }
    
    private var shouldShowTechnicalDetails: Bool {
        // LocalizedErrorでない場合、または詳細情報が異なる場合のみ表示
        if let localizedError = error as? LocalizedError {
            return localizedError.errorDescription != error.localizedDescription
        }
        return false
    }
    
    @ViewBuilder
    private var primaryActionButton: some View {
        if error is GitHubTokenError {
            Button(action: {
                // 設定画面を開く
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference") {
                    NSWorkspace.shared.open(url)
                }
            }) {
                HStack {
                    Image(systemName: "gear")
                    Text("設定を開く")
                }
                .font(.body)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
        } else if let commitError = error as? CommitError {
            switch commitError {
            case .networkError:
                Button(action: {
                    // 再試行（dismissして自動で再実行される想定）
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("再試行")
                    }
                    .font(.body)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
            default:
                EmptyView()
            }
        } else {
            EmptyView()
        }
    }
}
