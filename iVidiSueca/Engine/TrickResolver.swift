import Foundation

enum TrickResolver {
    static func winner(of trick: Trick, trump: Suit) -> PlayerPosition {
        winningCard(of: trick, trump: trump).position
    }

    /// The card currently taking the trick: the highest trump, else the highest card of the suit led.
    static func winningCard(of trick: Trick, trump: Suit) -> PlayedCard {
        precondition(!trick.cardsPlayed.isEmpty, "cannot resolve an empty trick")
        let trumps = trick.cardsPlayed.filter { $0.card.suit == trump }
        let contenders = trumps.isEmpty ? trick.cardsPlayed.filter { $0.card.suit == trick.leadSuit } : trumps
        return contenders.max { $0.card.rank < $1.card.rank }!
    }
}
