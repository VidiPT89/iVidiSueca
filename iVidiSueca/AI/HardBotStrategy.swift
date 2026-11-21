import Foundation

/// Plays like the Medium bot but tracks every card seen so far, leading side-suit
/// "master" cards that no remaining card of that suit can beat.
/// A master can still be cut by an opponent void in that suit.
struct HardBotStrategy: BotStrategy {
    func chooseCard(from legalMoves: [Card], hand: [Card], context: BotContext) -> Card {
        guard context.currentTrick.cardsPlayed.isEmpty else {
            return BotHeuristics.respond(from: legalMoves, context: context)
        }

        let seen = seenRanks(hand: hand, context: context)
        let masters = legalMoves.filter { card in
            card.suit != context.trump
                && Rank.allCases.allSatisfy { $0 <= card.rank || seen[card.suit, default: []].contains($0) }
        }
        if let master = masters.max(by: { $0.rank < $1.rank }) {
            return master
        }
        return BotHeuristics.discard(from: legalMoves, trump: context.trump)
    }

    /// Ranks of each suit that are no longer in an opponent's or partner's hand.
    private func seenRanks(hand: [Card], context: BotContext) -> [Suit: Set<Rank>] {
        let played = (context.completedTricks + [context.currentTrick]).flatMap { $0.cardsPlayed.map(\.card) }
        return Dictionary(grouping: hand + played, by: \.suit).mapValues { Set($0.map(\.rank)) }
    }
}
