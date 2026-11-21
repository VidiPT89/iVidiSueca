import Foundation

// The command-line harness exercises the production engine without importing SwiftUI.
enum AIDifficulty { case easy, normal, hard }

@main
struct EngineChecks {
    static func context(_ trick: Trick, position: PlayerPosition = .east) -> BotContext {
        BotContext(position: position, trump: .spades, currentTrick: trick, completedTricks: [],
                   teamAPoints: 0, teamBPoints: 0, cardsRemainingInOthersHands: 2)
    }

    static func main() {
        let deck = DeckBuilder.fullDeck()
        precondition(deck.count == 40 && Set(deck.map { "\($0.suit)-\($0.rank)" }).count == 40)
        precondition(deck.reduce(0) { $0 + $1.pointValue } == 120)
        precondition(ScoreCalculator.handWinner(teamAPoints: 60, teamBPoints: 60) == nil)

        for strategy in [MediumBotStrategy() as BotStrategy, HardBotStrategy() as BotStrategy] {
            // Following a suit cannot beat a trump, even with the ace.
            var cut = Trick()
            cut.play(Card(suit: .hearts, rank: .king), by: .south)
            cut.play(Card(suit: .hearts, rank: .two), by: .west)
            cut.play(Card(suit: .spades, rank: .three), by: .north)
            let hand = [Card(suit: .hearts, rank: .ace), Card(suit: .hearts, rank: .four)]
            precondition(strategy.chooseCard(from: hand, hand: hand, context: context(cut)).rank == .four)

            // Use the cheapest trump that beats the existing cut, not an undertrump.
            var overcut = Trick()
            overcut.play(Card(suit: .hearts, rank: .ace), by: .south)
            overcut.play(Card(suit: .hearts, rank: .two), by: .west)
            overcut.play(Card(suit: .spades, rank: .king), by: .north)
            let trumps = [Card(suit: .spades, rank: .two), Card(suit: .spades, rank: .seven), Card(suit: .spades, rank: .ace)]
            precondition(strategy.chooseCard(from: trumps, hand: trumps, context: context(overcut)).rank == .seven)
        }

        // Random complete deals: every strategy must play legally and conserve cards/points.
        for game in 0..<300 {
            let deal = DealerService.deal(dealer: PlayerPosition.allCases[game % 4])
            var hands = deal.players.mapValues(\.hand)
            var leader = PlayerPosition.allCases[game % 4].next
            var history: [Trick] = []
            var played = Set<UUID>()
            var a = 0, b = 0
            for _ in 0..<10 {
                var trick = Trick()
                var seat = leader
                for _ in 0..<4 {
                    let hand = hands[seat]!
                    let legal = RulesEngine.legalMoves(hand: hand, trick: trick, trump: deal.trumpSuit)
                    let ctx = BotContext(position: seat, trump: deal.trumpSuit, currentTrick: trick,
                                         completedTricks: history, teamAPoints: a, teamBPoints: b,
                                         cardsRemainingInOthersHands: hand.count)
                    let strategies: [BotStrategy] = [EasyBotStrategy(), MediumBotStrategy(), HardBotStrategy()]
                    let card = strategies[(game + seat.rawValue) % 3].chooseCard(from: legal, hand: hand, context: ctx)
                    precondition(legal.contains(card) && played.insert(card.id).inserted)
                    hands[seat]!.removeAll { $0.id == card.id }
                    trick.play(card, by: seat)
                    seat = seat.next
                }
                leader = TrickResolver.winner(of: trick, trump: deal.trumpSuit)
                ScoreCalculator.addPoints(from: trick, winner: leader, teamAPoints: &a, teamBPoints: &b)
                trick.winner = leader
                history.append(trick)
            }
            precondition(a + b == 120 && played.count == 40 && hands.values.allSatisfy(\.isEmpty))
        }
        print("PASS: 300 complete hands, 12,000 legal plays, cut/overtrump regressions and 60–60 draw")
    }
}
