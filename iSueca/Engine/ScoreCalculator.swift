import Foundation

enum ScoreCalculator {
    static let totalPoints = 120
    static let winThreshold = 61
    /// A match ("partida") is won by the first team to collect this many games.
    static let gamesToWinMatch = 4

    static func addPoints(from trick: Trick, winner: PlayerPosition, teamAPoints: inout Int, teamBPoints: inout Int) {
        let points = trick.points
        switch winner.team {
        case .teamA: teamAPoints += points
        case .teamB: teamBPoints += points
        }
    }

    static func handWinner(teamAPoints: Int, teamBPoints: Int) -> Team? {
        if teamAPoints >= winThreshold { return .teamA }
        if teamBPoints >= winThreshold { return .teamB }
        return nil
    }

    static func isSueca(teamPoints: Int) -> Bool {
        teamPoints == totalPoints
    }

    /// Games a hand is worth to the team that won it: 1 for 61–90 points,
    /// 2 for 91–119 (the losers failed to reach 30), 4 for a sueca (all 120).
    static func gamesAwarded(winnerPoints: Int) -> Int {
        switch winnerPoints {
        case totalPoints: return 4
        case 91..<totalPoints: return 2
        case winThreshold...: return 1
        default: return 0
        }
    }
}
