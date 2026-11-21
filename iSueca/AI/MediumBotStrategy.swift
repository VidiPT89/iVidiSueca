import Foundation

/// Simple heuristics: leads low side suits, cuts only to win, never burns an Ace or 7
/// for nothing, and loads points onto a trick its team has already won.
struct MediumBotStrategy: BotStrategy {
    func chooseCard(from legalMoves: [Card], hand: [Card], context: BotContext) -> Card {
        guard !context.currentTrick.cardsPlayed.isEmpty else {
            return BotHeuristics.discard(from: legalMoves, trump: context.trump)
        }
        return BotHeuristics.respond(from: legalMoves, context: context)
    }
}
