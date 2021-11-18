//
//  MemorizeApp.swift
//  Memorize
//
//  Created by Joeny Bui on 10/29/21.
//

import SwiftUI

@main
struct MemorizeApp: App {
    let game = EmojiMemoryGame()
    
    var body: some Scene {
        WindowGroup {
            EmojiMemoryGameView(game: game)
        }
    }
}
