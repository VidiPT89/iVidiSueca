import Foundation

/// Context handed to a bot so it can reason about the table without touching hidden hands.
struct BotContext {
    let position: PlayerPosition
    let trump: Suit
    let currentTrick: Trick
    let completedTricks: [Trick]
}

protocol BotStrategy {
    func chooseCard(from legalMoves: [Card], hand: [Card], context: BotContext) -> Card
}

func makeBotStrategy(for difficulty: AIDifficulty) -> BotStrategy {
    switch difficulty {
    case .easy: return EasyBotStrategy()
    case .normal: return MediumBotStrategy()
    case .hard: return HardBotStrategy()
    }
}

/// Play decisions shared by the Medium and Hard bots once a trick has been led.
enum BotHeuristics {
    /// Takes the trick as cheaply as possible when an opponent is winning, feeds points to a
    /// partner who is sure to win it, and otherwise throws away the least valuable card.
    static func respond(from legalMoves: [Card], context: BotContext) -> Card {
        let trick = context.currentTrick
        let winning = TrickResolver.winningCard(of: trick, trump: context.trump)
        let isLastToPlay = trick.cardsPlayed.count == 3

        if winning.position.team == context.position.team {
            return isLastToPlay ? givePoints(from: legalMoves, trump: context.trump)
                                : discard(from: legalMoves, trump: context.trump)
        }
        return cheapestWinner(from: legalMoves, context: context)
            ?? discard(from: legalMoves, trump: context.trump)
    }

    /// The weakest card that would take the trick, preferring the suit led over a trump.
    static func cheapestWinner(from legalMoves: [Card], context: BotContext) -> Card? {
        legalMoves
            .filter { card in
                var trial = context.currentTrick
                trial.play(card, by: context.position)
                return TrickResolver.winner(of: trial, trump: context.trump) == context.position
            }
            .min { lhs, rhs in
                let lhsTrump = lhs.suit == context.trump, rhsTrump = rhs.suit == context.trump
                return lhsTrump != rhsTrump ? !lhsTrump : lhs.rank < rhs.rank
            }
    }

    /// Least useful card: avoids trumps, Aces and 7s whenever there is a choice.
    static func discard(from legalMoves: [Card], trump: Suit) -> Card {
        let nonTrump = legalMoves.filter { $0.suit != trump }
        let pool = nonTrump.isEmpty ? legalMoves : nonTrump
        let safe = pool.filter { !$0.isHighValue }
        return cheapest(safe.isEmpty ? pool : safe)
    }

    /// Richest non-trump card for a trick the team has already won; the weakest trump otherwise.
    static func givePoints(from legalMoves: [Card], trump: Suit) -> Card {
        let nonTrump = legalMoves.filter { $0.suit != trump }
        if let richest = nonTrump.max(by: { ($0.pointValue, $0.rank) < ($1.pointValue, $1.rank) }) {
            return richest
        }
        return legalMoves.min { $0.rank < $1.rank }!
    }

    static func cheapest(_ cards: [Card]) -> Card {
        cards.min { ($0.pointValue, $0.rank) < ($1.pointValue, $1.rank) }!
    }
}
