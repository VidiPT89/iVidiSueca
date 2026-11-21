import Foundation
import SwiftUI
import UIKit

enum GamePhase: Equatable {
    case menu
    case dealing
    case playing
    case trickEnd
    case handEnd
}

enum DealingStage: Equatable {
    case revealTrump
    case dealCards
    case announceLeader
}

struct HandResult: Equatable {
    let teamAPoints: Int
    let teamBPoints: Int
    let winner: Team?
    let wasSueca: Bool
    /// Games this hand added to the winner's match tally (0 for a 60–60 draw).
    let gamesAwarded: Int
    /// Set once a team reaches `ScoreCalculator.gamesToWinMatch`.
    let matchWinner: Team?
}

@MainActor
final class GameViewModel: ObservableObject {
    @Published private(set) var phase: GamePhase = .menu
    @Published private(set) var handsByPosition: [PlayerPosition: [Card]] = [:]
    @Published private(set) var trumpSuit: Suit = .spades
    @Published private(set) var trumpCard: Card?
    @Published private(set) var currentTrick = Trick()
    @Published private(set) var teamAPoints = 0
    @Published private(set) var teamBPoints = 0
    @Published private(set) var teamAGames = 0
    @Published private(set) var teamBGames = 0
    @Published private(set) var currentPlayerTurn: PlayerPosition = .south
    @Published private(set) var lastTrickWinner: PlayerPosition?
    @Published private(set) var handResult: HandResult?
    @Published private(set) var completedTricks: [Trick] = []
    @Published private(set) var dealingStage: DealingStage?
    /// The last card the player tried to play illegally; the view shakes it.
    @Published private(set) var rejectedCard: Card?
    /// Bumped on every illegal attempt, so repeated taps on the same card shake it again.
    @Published private(set) var rejectionCount = 0
    @Published private(set) var isPaused = false

    /// Every seat's real hand. `handsByPosition` lags behind it while cards are being dealt.
    private var hands: [PlayerPosition: [Card]] = [:]
    private var pendingTask: Task<Void, Never>?
    private var settings: SettingsViewModel?
    private var dealer: PlayerPosition = .west
    private let feedback = UIImpactFeedbackGenerator(style: .light)

    func configure(settings: SettingsViewModel) {
        self.settings = settings
    }

    private var forcedCut: Bool { settings?.forcedCut ?? false }

    var humanLegalMoves: [Card] {
        guard phase == .playing else { return [] }
        return RulesEngine.legalMoves(hand: hands[.south] ?? [], trick: currentTrick, trump: trumpSuit, forcedCut: forcedCut)
    }

    var isMatchOver: Bool { handResult?.matchWinner != nil }

    // MARK: - Flow

    func startNewMatch() {
        teamAGames = 0
        teamBGames = 0
        dealer = PlayerPosition.allCases.randomElement() ?? .west
        beginHand()
    }

    /// Deals the next hand of the match, or starts a new match once one has been decided.
    func continueAfterHand() {
        if isMatchOver {
            startNewMatch()
        } else {
            dealer = dealer.next
            beginHand()
        }
    }

    func returnToMenu() {
        pendingTask?.cancel()
        isPaused = false
        dealingStage = nil
        phase = .menu
        handResult = nil
    }

    func setPaused(_ paused: Bool) {
        isPaused = paused
    }

    var suggestedCard: Card? {
        guard phase == .playing, currentPlayerTurn == .south else { return nil }
        let legal = humanLegalMoves
        guard !legal.isEmpty else { return nil }
        let context = BotContext(position: .south, trump: trumpSuit, currentTrick: currentTrick,
                                 completedTricks: completedTricks)
        return HardBotStrategy().chooseCard(from: legal, hand: hands[.south] ?? [], context: context)
    }

    /// Pausing freezes the remaining delay, including distribution and trick collection.
    private func wait(seconds: Double) async -> Bool {
        var remaining = seconds
        while remaining > 0 || isPaused {
            do { try await Task.sleep(nanoseconds: 50_000_000) }
            catch { return false }
            if !isPaused { remaining -= 0.05 }
        }
        return !Task.isCancelled
    }

    private func beginHand() {
        pendingTask?.cancel()
        isPaused = false
        rejectedCard = nil
        let deal = DealerService.deal(dealer: dealer)
        hands = deal.hands
        trumpSuit = deal.trumpSuit
        trumpCard = nil
        currentTrick = Trick()
        teamAPoints = 0
        teamBPoints = 0
        currentPlayerTurn = dealer.next
        lastTrickWinner = nil
        handResult = nil
        completedTricks = []
        handsByPosition = [.south: [], .west: [], .north: [], .east: []]

        phase = .dealing
        runDealingSequence(trumpCard: deal.trumpCard)
    }

    private func runDealingSequence(trumpCard: Card) {
        let finalHands = hands
        pendingTask = Task {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                self.dealingStage = .revealTrump
                self.trumpCard = trumpCard
            }
            SoundPlayer.play(.trickWin)
            guard await self.wait(seconds: 0.9) else { return }

            withAnimation(.easeInOut(duration: 0.2)) {
                self.dealingStage = .dealCards
            }

            let cardsPerHand = finalHands.values.map(\.count).max() ?? 10
            for round in 0..<cardsPerHand {
                withAnimation(.easeOut(duration: 0.16)) {
                    for position in PlayerPosition.allCases {
                        guard let hand = finalHands[position], round < hand.count else { continue }
                        self.handsByPosition[position, default: []].append(hand[round])
                    }
                }
                SoundPlayer.play(.cardPlay)
                guard await self.wait(seconds: 0.065) else { return }
            }

            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                self.dealingStage = .announceLeader
            }
            guard await self.wait(seconds: 1.1) else { return }

            withAnimation(.easeOut(duration: 0.25)) {
                self.dealingStage = nil
            }
            self.phase = .playing
            self.advanceIfNeeded()
        }
    }

    // MARK: - Playing

    func playHumanCard(_ card: Card) {
        guard !isPaused, phase == .playing, currentPlayerTurn == .south else { return }
        guard humanLegalMoves.contains(card) else {
            rejectedCard = card
            rejectionCount += 1
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            SoundPlayer.play(.illegalMove)
            return
        }
        play(card, by: .south)
    }

    private func play(_ card: Card, by position: PlayerPosition) {
        feedback.impactOccurred()
        SoundPlayer.play(.cardPlay)
        hands[position]?.removeAll { $0.id == card.id }
        handsByPosition[position] = hands[position]
        currentTrick.play(card, by: position)
        rejectedCard = nil

        if currentTrick.isComplete {
            resolveTrick()
        } else {
            currentPlayerTurn = position.next
            advanceIfNeeded()
        }
    }

    private func resolveTrick() {
        phase = .trickEnd
        let winner = TrickResolver.winner(of: currentTrick, trump: trumpSuit)
        ScoreCalculator.addPoints(from: currentTrick, winner: winner, teamAPoints: &teamAPoints, teamBPoints: &teamBPoints)
        lastTrickWinner = winner
        var finished = currentTrick
        finished.winner = winner
        completedTricks.append(finished)
        UINotificationFeedbackGenerator().notificationOccurred(winner.team == .teamA ? .success : .warning)
        SoundPlayer.play(.trickWin)

        pendingTask = Task {
            guard await self.wait(seconds: 0.9) else { return }
            self.currentTrick = Trick()
            self.currentPlayerTurn = winner

            if self.completedTricks.count >= 10 {
                self.finishHand()
            } else {
                self.phase = .playing
                self.advanceIfNeeded()
            }
        }
    }

    private func finishHand() {
        let winner = ScoreCalculator.handWinner(teamAPoints: teamAPoints, teamBPoints: teamBPoints)
        let winnerPoints = winner == .teamA ? teamAPoints : winner == .teamB ? teamBPoints : 0
        let wasSueca = ScoreCalculator.isSueca(teamPoints: winnerPoints)
        let games = ScoreCalculator.gamesAwarded(winnerPoints: winnerPoints)
        switch winner {
        case .teamA: teamAGames += games
        case .teamB: teamBGames += games
        case nil: break
        }

        let target = ScoreCalculator.gamesToWinMatch
        let matchWinner: Team? = teamAGames >= target ? .teamA : teamBGames >= target ? .teamB : nil
        handResult = HandResult(teamAPoints: teamAPoints, teamBPoints: teamBPoints, winner: winner,
                                wasSueca: wasSueca, gamesAwarded: games, matchWinner: matchWinner)

        let stats = MatchStatsStore.shared
        stats.recordHandResult(humanTeamWon: winner == .teamA, suecaByHuman: wasSueca && winner == .teamA)
        if let matchWinner { stats.recordMatchResult(humanTeamWon: matchWinner == .teamA) }

        UINotificationFeedbackGenerator().notificationOccurred(winner == .teamA ? .success : .error)
        SoundPlayer.play(.handEnd)
        phase = .handEnd
    }

    private func advanceIfNeeded() {
        guard phase == .playing, currentPlayerTurn != .south else { return }
        let position = currentPlayerTurn
        let strategy = makeBotStrategy(for: settings?.aiDifficulty ?? .normal)
        let speedRange = (settings?.aiSpeed ?? .normal).delayRange

        pendingTask = Task {
            guard await self.wait(seconds: Double.random(in: speedRange)) else { return }
            guard self.phase == .playing, self.currentPlayerTurn == position else { return }
            let hand = self.hands[position] ?? []
            let legal = RulesEngine.legalMoves(hand: hand, trick: self.currentTrick, trump: self.trumpSuit,
                                               forcedCut: self.forcedCut)
            let context = BotContext(position: position, trump: self.trumpSuit, currentTrick: self.currentTrick,
                                     completedTricks: self.completedTricks)
            self.play(strategy.chooseCard(from: legal, hand: hand, context: context), by: position)
        }
    }
}
