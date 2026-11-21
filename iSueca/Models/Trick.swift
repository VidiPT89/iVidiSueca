import Foundation

struct PlayedCard: Identifiable, Equatable {
    var id: UUID { card.id }
    let position: PlayerPosition
    let card: Card
}

struct Trick {
    var cardsPlayed: [PlayedCard] = []
    var winner: PlayerPosition?

    var leadSuit: Suit? { cardsPlayed.first?.card.suit }

    var isComplete: Bool { cardsPlayed.count == 4 }

    var points: Int { cardsPlayed.reduce(0) { $0 + $1.card.pointValue } }

    mutating func play(_ card: Card, by position: PlayerPosition) {
        cardsPlayed.append(PlayedCard(position: position, card: card))
    }
}
