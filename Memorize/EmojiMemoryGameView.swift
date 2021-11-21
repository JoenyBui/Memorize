//
//  EmojiMemoryGameView.swift
//  Memorize
//
//  Created by Joeny Bui on 10/29/21.
//

import SwiftUI

struct EmojiMemoryGameView: View {
    @ObservedObject var game: EmojiMemoryGame
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack {
                gameBody
                
                HStack {
                    restart
                    Spacer()
                    shuffle
                }.padding(.horizontal)
                
            }
            deckBody
            .padding()
        }
    }
    
    @State private var dealt = Set<Int>()
    
    private func deal(_ card: EmojiMemoryGame.Card) {
        dealt.insert(card.id)
    }
    
    private func isUndealth(_ card: EmojiMemoryGame.Card) -> Bool {
        return !dealt.contains(card.id)
    }
    
    @Namespace private var dealingNamespace
    
    private func dealAnimation(for card: EmojiMemoryGame.Card) -> Animation {
        var delay = 0.0
        if let index = game.cards.firstIndex(where: {$0.id == card.id}) {
            delay = Double(index)*(CardConstants.totalDealDuration / Double(game.cards.count))
        }
        return Animation.easeInOut(duration: CardConstants.dealDuration).delay(delay)
    }
    
    private func zIndex(of card: EmojiMemoryGame.Card) -> Double {
        -Double(game.cards.firstIndex(where: {$0.id == card.id}) ?? 0)
    }
    
    var gameBody: some View {
        AspectVGrid(items: game.cards, aspectRatio: 2/3) {card in
            if isUndealth(card) || (card.isMatched && !card.isFaceUp) {
                Color.clear
            } else {
                CardView(card: card)
                    .matchedGeometryEffect(id: card.id, in: dealingNamespace)
                    .padding(4)
                    .transition(AnyTransition.asymmetric(insertion: .identity, removal: .scale))
                    .zIndex(zIndex(of: card))
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 1)) {
                            game.choose(card)
                        }
                    }
            }
        }
        .foregroundColor(CardConstants.color)
    }
    
    var deckBody: some View {
        ZStack {
            ForEach(game.cards.filter(isUndealth)) {card in
                CardView(card: card)
                    .matchedGeometryEffect(id: card.id, in: dealingNamespace)
                    .transition(AnyTransition.asymmetric(insertion: .opacity, removal: .identity))
                    .zIndex(zIndex(of: card))
            }
        }
        .frame(width: CardConstants.undealtWidth, height: CardConstants.undealtHeight)
        .foregroundColor(CardConstants.color)
        .onTapGesture {
            // "deal" cards
            for card in game.cards {
                
                withAnimation(dealAnimation(for: card)) {
                    deal(card)
                }
            }
        }
    }
    var shuffle: some View {
        Button("Shuffle") {
            withAnimation {
                game.shuffle()
            }
        }
    }
    
    var restart: some View {
        Button("Restart") {
            withAnimation {
                dealt = []
                game.restart()
            }
        }
    }
    private struct CardConstants {
        static let color = Color.red
        static let aspectRatio: CGFloat = 2/3
        static let dealDuration: Double = 0.5
        static let totalDealDuration: Double = 2
        static let undealtHeight: CGFloat = 90
        static let undealtWidth = undealtHeight * aspectRatio
    }
}

struct CardView: View {
    let card: EmojiMemoryGame.Card
    
    @State private var animatedBonusRemaining: Double = 0
    
    var body: some View {
            GeometryReader { geometry in
                ZStack {
                    // Group is a "bag of Lego" container
                    // it's useful for propagating view modifiers to multiple views
                    // (as we are doing below, for example, with opacity)
                    Group {
                        // card.isConsumingBonusTime is changed by the Model quite often
                        // it changes any time a card's isFaceUp changes (or isMatched)
                        // so the two Pies here are swapping back and forth as isFaceUp changes
                        // any time we are not consuming bonus time, the lower Pie appears
                        // (it is not animated and is just showing how much time is left)
                        // any time we ARE consuming bonus time, the upper Pie appears
                        // and when it appears (onAppear), it starts animating its own endAngle
                        // by first setting its animatedBonusRemaining to however much time is remaining
                        // then animating setting that to zero inside an explicit animation
                        // (and since this represents a change to animatedBonusRemaining, it will animate that change)
                        // if isConsumingBonusTime changes in the middle of the animation
                        // the top Pie below will simply be removed from the UI and the animation abandoned
                        if card.isConsumingBonusTime {
                            Pie(startAngle: Angle(degrees: 0-90), endAngle: Angle(degrees: (1-animatedBonusRemaining)*360-90))
                                .onAppear {
                                    animatedBonusRemaining = card.bonusRemaining
                                    withAnimation(.linear(duration: card.bonusTimeRemaining)) {
                                        animatedBonusRemaining = 0
                                    }
                                }
                        } else {
                            Pie(startAngle: Angle(degrees: 0-90), endAngle: Angle(degrees: (1-card.bonusRemaining)*360-90))
                        }
                    }
                        .padding(5)
                        .opacity(0.5)
                    Text(card.content)
                        .rotationEffect(Angle.degrees(card.isMatched ? 360 : 0))
                        // only view modifiers ABOVE this .animation call are animated by it
                        .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false))
                        .padding(5)
                        .font(Font.system(size: DrawingConstants.fontSize))
                        // view modifications like this .scaleEffect are not affected by the call to .animation ABOVE it
                        .scaleEffect(scale(thatFits: geometry.size))
                }
                // this is the same as .modifier(Cardify(isFaceUp: card.isFaceUp))
                // it turns our ZStack with a Pie and a Text in it into a "card" on screen
                // it does this by just returning its own ZStack with RoundedRectangles and such in it
                // see Cardify.swift
                .cardify(isFaceUp: card.isFaceUp)
            }
        }
//    
//    var body: some View {
//        GeometryReader {geometry in
//            ZStack {
//                Group {
//                    if card.isConsumingBonusTime {
//                        Pie(
//                            startAngle: Angle(degrees: 0.0-90.0),
//                            endAngle: Angle(degrees: (1-card.animatedBonusRemaining)*360.0-90.0)
//                        ).onAppear {
//                            animatedBonusRemaining = card.bonusRemaining
//                            withAnimation(.linear(duration: card.bonusTimeRemaining)) {
//                                animatedBonusRemaining = 0
//                            }
//                        }
//                    } else {
//                        Pie(
//                            startAngle: Angle(degrees: 0.0-90.0),
//                            endAngle: Angle(degrees: (1-card.bonusRemaining)*360.0-90.0)
//                        )
//                    }
//                }
//                    .padding(5)
//                    .opacity(0.5)
//                Text(card.content)
//                    .rotationEffect(Angle.degrees(card.isMatched ? 360 : 0))
//                    .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false))
//                    .font(Font.system(size: DrawingConstants.fontSize))
//                    .scaleEffect(scale(thatFits: geometry.size))
//            }
//            .cardify(isFaceUp: card.isFaceUp)
//        }
//    }
    
    private func scale(thatFits size: CGSize) -> CGFloat {
        min(size.width, size.height) / (DrawingConstants.fontSize / DrawingConstants.fontScale)
    }
    
    private func font(in size: CGSize) -> Font {
        Font.system(size: min(size.width, size.height) * DrawingConstants.fontScale)
    }
    
    private struct DrawingConstants {
//        static let cornerRadius: CGFloat = 10
//        static let lineWidth: CGFloat = 3
        static let fontScale: CGFloat = 0.70
        static let fontSize: CGFloat = 32
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let game = EmojiMemoryGame()
//        game.choose(game.cards.first!)
        Group {
            EmojiMemoryGameView(game: game)
                .preferredColorScheme(.light)
                
            EmojiMemoryGameView(game: game)
                .preferredColorScheme(.dark)
        }
    }
}
