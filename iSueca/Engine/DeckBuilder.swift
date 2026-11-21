import Foundation

enum DeckBuilder {
    static func fullDeck() -> [Card] {
        Suit.allCases.flatMap { suit in Rank.allCases.map { Card(suit: suit, rank: $0) } }
    }

    static func shuffledDeck() -> [Card] {
        fullDeck().shuffled()
    }
}
