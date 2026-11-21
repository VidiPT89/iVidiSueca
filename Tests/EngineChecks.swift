import Foundation

// The command-line harness exercises the production engine without importing SwiftUI.
enum AIDifficulty { case easy, normal, hard }

@main
struct EngineChecks {
    static func context(_ trick: Trick, position: PlayerPosition = .east) -> BotContext {
        BotContext(position: position, trump: .spades, currentTrick: trick, completedTricks: [])
    }

    static func trick(_ plays: [(Suit, Rank, PlayerPosition)]) -> Trick {
        var trick = Trick()
        for (suit, rank, seat) in plays { trick.play(Card(suit: suit, rank: rank), by: seat) }
        return trick
    }

    static func main() {
        let deck = DeckBuilder.fullDeck()
        precondition(deck.count == 40 && Set(deck.map { "\($0.suit)-\($0.rank)" }).count == 40)
        precondition(deck.reduce(0) { $0 + $1.pointValue } == 120)

        // Scoring: 60–60 is a draw; games per hand are 1 / 2 / 4.
        precondition(ScoreCalculator.handWinner(teamAPoints: 60, teamBPoints: 60) == nil)
        precondition(ScoreCalculator.gamesAwarded(winnerPoints: 0) == 0)
        precondition(ScoreCalculator.gamesAwarded(winnerPoints: 61) == 1)
        precondition(ScoreCalculator.gamesAwarded(winnerPoints: 90) == 1)
        precondition(ScoreCalculator.gamesAwarded(winnerPoints: 91) == 2)
        precondition(ScoreCalculator.gamesAwarded(winnerPoints: 119) == 2)
        precondition(ScoreCalculator.gamesAwarded(winnerPoints: 120) == 4)

        // Rules: follow suit is mandatory; cutting is only forced under the house rule.
        let led = trick([(.hearts, .king, .south)])
        let voidHand = [Card(suit: .spades, rank: .two), Card(suit: .clubs, rank: .ace)]
        precondition(RulesEngine.legalMoves(hand: voidHand, trick: led, trump: .spades).count == 2)
        precondition(RulesEngine.legalMoves(hand: voidHand, trick: led, trump: .spades, forcedCut: true).map(\.suit) == [.spades])
        let mixedHand = voidHand + [Card(suit: .hearts, rank: .two)]
        precondition(RulesEngine.legalMoves(hand: mixedHand, trick: led, trump: .spades).map(\.suit) == [.hearts])

        for strategy in [MediumBotStrategy() as BotStrategy, HardBotStrategy() as BotStrategy] {
            // Following a suit cannot beat a trump, even with the ace.
            let cut = trick([(.hearts, .king, .south), (.hearts, .two, .west), (.spades, .three, .north)])
            let hand = [Card(suit: .hearts, rank: .ace), Card(suit: .hearts, rank: .four)]
            precondition(strategy.chooseCard(from: hand, hand: hand, context: context(cut)).rank == .four)

            // Use the cheapest trump that beats the existing cut, not an undertrump.
            let overcut = trick([(.hearts, .ace, .south), (.hearts, .two, .west), (.spades, .king, .north)])
            let trumps = [Card(suit: .spades, rank: .two), Card(suit: .spades, rank: .seven), Card(suit: .spades, rank: .ace)]
            precondition(strategy.chooseCard(from: trumps, hand: trumps, context: context(overcut)).rank == .seven)

            // Last to play with the partner winning: load points, never waste a trump.
            let partnerWins = trick([(.hearts, .two, .west), (.hearts, .ace, .north), (.hearts, .three, .east)])
            let discards = [Card(suit: .spades, rank: .ace), Card(suit: .clubs, rank: .seven), Card(suit: .clubs, rank: .two)]
            let given = strategy.chooseCard(from: discards, hand: discards, context: context(partnerWins, position: .south))
            precondition(given.suit == .clubs && given.rank == .seven)

            // An opponent winning and no way to beat them: throw the cheapest side card.
            let lost = trick([(.hearts, .ace, .south)])
            let rubbish = [Card(suit: .clubs, rank: .ace), Card(suit: .diamonds, rank: .four), Card(suit: .spades, rank: .two)]
            let thrown = strategy.chooseCard(from: rubbish, hand: rubbish, context: context(lost, position: .west))
            precondition(thrown.suit == .spades || thrown.rank == .four, "should cut or discard low, not burn an ace")
        }

        // Hard leads a master card once every stronger card of that suit has gone.
        var history = trick([(.clubs, .ace, .south), (.clubs, .two, .west), (.clubs, .three, .north), (.clubs, .four, .east)])
        history.winner = .south
        let hardHand = [Card(suit: .clubs, rank: .seven), Card(suit: .diamonds, rank: .two)]
        let hardContext = BotContext(position: .west, trump: .spades, currentTrick: Trick(), completedTricks: [history])
        precondition(HardBotStrategy().chooseCard(from: hardHand, hand: hardHand, context: hardContext).rank == .seven)

        // Random complete deals under both rule sets: every strategy plays legally and conserves cards/points.
        let strategies: [BotStrategy] = [EasyBotStrategy(), MediumBotStrategy(), HardBotStrategy()]
        for game in 0..<300 {
            let forcedCut = game.isMultiple(of: 2)
            let deal = DealerService.deal(dealer: PlayerPosition.allCases[game % 4])
            precondition(deal.hands.values.allSatisfy { $0.count == 10 })
            var hands = deal.hands
            var leader = PlayerPosition.allCases[game % 4].next
            var completed: [Trick] = []
            var played = Set<UUID>()
            var a = 0, b = 0
            for _ in 0..<10 {
                var trick = Trick()
                var seat = leader
                for _ in 0..<4 {
                    let hand = hands[seat]!
                    let legal = RulesEngine.legalMoves(hand: hand, trick: trick, trump: deal.trumpSuit, forcedCut: forcedCut)
                    let ctx = BotContext(position: seat, trump: deal.trumpSuit, currentTrick: trick, completedTricks: completed)
                    let card = strategies[(game + seat.rawValue) % 3].chooseCard(from: legal, hand: hand, context: ctx)
                    precondition(legal.contains(card) && played.insert(card.id).inserted)
                    hands[seat]!.removeAll { $0.id == card.id }
                    trick.play(card, by: seat)
                    seat = seat.next
                }
                leader = TrickResolver.winner(of: trick, trump: deal.trumpSuit)
                ScoreCalculator.addPoints(from: trick, winner: leader, teamAPoints: &a, teamBPoints: &b)
                trick.winner = leader
                completed.append(trick)
            }
            precondition(a + b == 120 && played.count == 40 && hands.values.allSatisfy(\.isEmpty))
        }
        print("PASS: rules, scoring, bot regressions and 300 complete hands (12,000 legal plays, both cut rules)")
    }
}
