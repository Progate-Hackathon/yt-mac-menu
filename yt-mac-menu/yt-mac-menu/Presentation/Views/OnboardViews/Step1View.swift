//
//  Step1View.swift
//  yt-mac-menu
//
//  Created by cmStudent on 2026/02/21.
//
import SwiftUI

struct Step1View: View {
    
    @State private var showTitle = false
    @State private var showDescription = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            
            // タイトル
            Text("Welcome サノス")
                .font(.system(size: 42, weight: .bold))
                .opacity(showTitle ? 1 : 0)
                .scaleEffect(showTitle ? 1 : 0.95)
                .offset(y: showTitle ? 0 : 20)
                .animation(.easeInOut(duration: 0.9), value: showTitle)
            
            // 説明文
            Text("""
サノスはジェスチャーによるショートカットを実装し、
開発作業に区切りを付けることができる、
パワフルな開発支援ツールです。
まずは初期設定をしてみましょう。
""")
                .font(.title3)
                .foregroundStyle(.secondary)
                .lineSpacing(6)
                .opacity(showDescription ? 1 : 0)
                .scaleEffect(showDescription ? 1 : 0.98)
                .offset(y: showDescription ? 0 : 15)
                .animation(.easeInOut(duration: 1.0), value: showDescription)
            
            Spacer()
            
            }
        .padding(60)
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
    Step1View()
}

