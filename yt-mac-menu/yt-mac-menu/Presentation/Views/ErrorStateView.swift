//
//  ErrorStateView.swift
//  yt-mac-menu
//
//  Created by アウン on 2026/02/15.
//

import SwiftUI

struct ErrorStateView: View {
    let error: Error
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("エラーが発生しました")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                if let localizedError = error as? LocalizedError {
                    if let errorDescription = localizedError.errorDescription {
                        Text(errorDescription)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    if let recoverySuggestion = localizedError.recoverySuggestion {
                        Text(recoverySuggestion)
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                } else {
                    Text(error.localizedDescription)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }
}
