//
//  GestureAction.swift
//  yt-mac-menu
//
//  Created by cmStudent on 2026/02/21.
//

import Foundation

/// ジェスチャー検出時に実行するアクション
struct GestureAction: Codable, Identifiable, Equatable {
    let id: UUID
    var actionType: ActionType
    var hotkey: Hotkey?        // .shortcut の場合のみ使用
    var commandString: String? // .command の場合のみ使用
    
    init(
        id: UUID = UUID(),
        actionType: ActionType = .shortcut,
        hotkey: Hotkey? = nil,
        commandString: String? = nil
    ) {
        self.id = id
        self.actionType = actionType
        self.hotkey = hotkey
        self.commandString = commandString
    }
    
    /// 最大アクション数
    static let maxActionsPerGesture = 10
}
