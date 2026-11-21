import Foundation

/// Tracks every card seen so far to reason about what opponents can still hold,
/// leads established suits and chooses the cheapest trump that actually wins.
/// A master of a suit can still be cut by an opponent void in that suit.
struct HardBotStrategy: BotStrategy {
    func chooseCard(from legalMoves: [Card], hand: [Card], context: BotContext) -> Card {
        let seen = seenCards(context: context, hand: hand)
        let trick = context.currentTrick

        if trick.cardsPlayed.isEmpty {
            return chooseLead(from: legalMoves, hand: hand, seen: seen, context: context)
        }

        guard let leadSuit = trick.leadSuit else {
            return legalMoves.min { $0.pointValue < $1.pointValue } ?? legalMoves[0]
        }

        let currentWinner = TrickResolver.winner(of: trick, trump: context.trump)
        let partnerWinning = currentWinner.team == context.position.team
        let isLastToPlay = trick.cardsPlayed.count == 3

        let followingSuit = legalMoves.contains { $0.suit == leadSuit }
        if followingSuit {
            let sameSuit = legalMoves.filter { $0.suit == leadSuit }
            if partnerWinning {
                if isLastToPlay {
                    return sameSuit.max { $0.pointValue < $1.pointValue } ?? sameSuit[0]
                }
                return sameSuit.min { $0.pointValue < $1.pointValue } ?? sameSuit[0]
            }
            let currentWinningCard = trick.cardsPlayed.first { $0.position == currentWinner }!.card
            let winningOptions = sameSuit.filter { $0.suit == currentWinningCard.suit && $0.rank > currentWinningCard.rank }
            if let cheapestWin = winningOptions.min(by: { $0.pointValue < $1.pointValue }) {
                return cheapestWin
            }
            return sameSuit.min { $0.pointValue < $1.pointValue } ?? sameSuit[0]
        }

        let trumps = legalMoves.filter { $0.suit == context.trump }
        if !trumps.isEmpty {
            if partnerWinning && trick.cardsPlayed.count == 3 {
                return legalMoves.max { $0.pointValue < $1.pointValue }!
            }
            if !partnerWinning {
                let winningTrumps = trumps.filter { card in
                    var trial = trick
                    trial.play(card, by: context.position)
                    return TrickResolver.winner(of: trial, trump: context.trump) == context.position
                }
                return winningTrumps.min { $0.rank < $1.rank }
                    ?? legalMoves.min { $0.pointValue < $1.pointValue }!
            }
            return chooseDiscard(from: legalMoves, seen: seen, context: context)
        }

        return chooseDiscard(from: legalMoves, seen: seen, context: context)
    }

    private func chooseLead(from legalMoves: [Card], hand: [Card], seen: Set<Card>, context: BotContext) -> Card {
        let nonTrump = legalMoves.filter { $0.suit != context.trump }
        let pool = nonTrump.isEmpty ? legalMoves : nonTrump

        for card in pool.sorted(by: { $0.rank > $1.rank }) {
            if isMasterCard(card, seen: seen, context: context) {
                return card
            }
        }

        let safe = pool.filter { $0.rank != .ace && $0.rank != .seven }
        return (safe.isEmpty ? pool : safe).min { $0.pointValue < $1.pointValue } ?? pool[0]
    }

    private func chooseDiscard(from legalMoves: [Card], seen: Set<Card>, context: BotContext) -> Card {
        let safe = legalMoves.filter { $0.rank != .ace && $0.rank != .seven }
        return (safe.isEmpty ? legalMoves : safe).min { $0.pointValue < $1.pointValue } ?? legalMoves[0]
    }

    /// A card is a "master" if every stronger card of its suit has already been played or seen.
    private func isMasterCard(_ card: Card, seen: Set<Card>, context: BotContext) -> Bool {
        for rank in Rank.allCases where rank > card.rank {
            let higher = Card(suit: card.suit, rank: rank)
            if !seen.contains(where: { $0.suit == higher.suit && $0.rank == higher.rank }) {
                return false
            }
        }
        return true
    }

    private func seenCards(context: BotContext, hand: [Card]) -> Set<Card> {
        var seen = Set<Card>(hand)
        for trick in context.completedTricks {
            for played in trick.cardsPlayed { seen.insert(played.card) }
        }
        for played in context.currentTrick.cardsPlayed { seen.insert(played.card) }
        return seen
    }
}
