import Foundation

enum PlayerPosition: Int, CaseIterable, Identifiable {
    case south = 0, west, north, east
    // South = human. South+North = Team A, West+East = Team B.

    var id: Int { rawValue }

    var next: PlayerPosition {
        PlayerPosition(rawValue: (rawValue + 1) % 4)!
    }

    var team: Team {
        switch self {
        case .south, .north: return .teamA
        case .west, .east: return .teamB
        }
    }

    var nameKey: String {
        switch self {
        case .south: return "player.you"
        case .north: return "player.partner"
        case .west: return "player.west"
        case .east: return "player.east"
        }
    }
}

enum Team {
    case teamA, teamB

    var nameKey: String {
        switch self {
        case .teamA: return "game.teamA"
        case .teamB: return "game.teamB"
        }
    }
}
