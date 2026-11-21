import Foundation

enum DealerService {
    struct DealResult {
        let hands: [PlayerPosition: [Card]]
        let trumpCard: Card
        var trumpSuit: Suit { trumpCard.suit }
    }

    /// Deals 10 cards to each of the 4 seats and reveals the dealer's last card as trump.
    static func deal(dealer: PlayerPosition) -> DealResult {
        var hands: [PlayerPosition: [Card]] = [:]
        var seat = dealer.next
        for card in DeckBuilder.shuffledDeck() {
            hands[seat, default: []].append(card)
            seat = seat.next
        }

        let trumpCard = hands[dealer]!.last!
        let sorted = hands.mapValues { sortForDisplay($0, trump: trumpCard.suit) }
        return DealResult(hands: sorted, trumpCard: trumpCard)
    }

    /// Trumps first, then the other suits; strongest card first within each suit.
    static func sortForDisplay(_ cards: [Card], trump: Suit) -> [Card] {
        cards.sorted { lhs, rhs in
            if lhs.suit == rhs.suit {
                return lhs.rank > rhs.rank
            }
            if lhs.suit == trump { return true }
            if rhs.suit == trump { return false }
            return lhs.suit.rawValue < rhs.suit.rawValue
        }
    }
}
