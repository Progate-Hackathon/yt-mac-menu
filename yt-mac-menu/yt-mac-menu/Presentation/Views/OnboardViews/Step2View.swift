//
//  Step2View.swift
//  yt-mac-menu
//
//  Created by cmStudent on 2026/02/21.
//
import SwiftUI

struct Step2View: View {
    @State private var showTitle = false
    @State private var showDescription = false
    var body: some View {
        VStack(spacing: 16) {
            Label("ステップ1", systemImage: "1.circle.fill")
                .font(.system(size: 42, weight: .bold))
                .opacity(showTitle ? 1 : 0)
                .scaleEffect(showTitle ? 1 : 0.95)
                .offset(y: showTitle ? 0 : 20)
                .animation(.easeInOut(duration: 0.9), value: showTitle)

            Text("ジェスチャーでコミットをするかショートカットを実行するかを選択できます。")
                .font(.title3)
                .foregroundStyle(.secondary)
                .lineSpacing(6)
                .opacity(showDescription ? 1 : 0)
                .scaleEffect(showDescription ? 1 : 0.98)
                .offset(y: showDescription ? 0 : 15)
                .animation(.easeInOut(duration: 1.0), value: showDescription)
                .padding()
            SelectCommitView()
            
           
        }.padding(60)
            .frame(minWidth: 520, minHeight: 380)

        .onAppear {
            showTitle = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                showDescription = true
            }
        }
        
    }
}
#Preview {
    Step2View()
}

