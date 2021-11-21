//
//  EmojiMemoryGame.swift
//  Memorize
//
//  Created by Joeny Bui on 11/4/21.
//

import SwiftUI


// ObservableObject is like pub-sub
class EmojiMemoryGame: ObservableObject {
    typealias Card = MemoryGame<String>.Card
    
    static let emojis = [
        "✈️",
        "🎯",
        "🚕",
        "🏸",
        "🎾",
        "🏊🏼",
        "🧘🏻‍♂️",
        "🏊🏾‍♀️",
        "🥑",
        "🍖",
        "🎱",
        "🔯",
        "💰",
        "💡"
    ]
    
    static func createMemoryGame() -> MemoryGame<String> {
        MemoryGame<String>(numberOfPairsOfCards: 8) {
            pairIndex in emojis[pairIndex]
        }
    }
    
    @Published private var model = createMemoryGame()
    
    var cards: Array<Card> {
        return model.cards
    }
    
    func choose(_ card: Card) {
        model.choose(card)
    }
    
    func shuffle() {
        model.shuffle()
    }
    
    func restart() {
        model = EmojiMemoryGame.createMemoryGame()
    }
}

