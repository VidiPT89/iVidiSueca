import Foundation

struct MatchStats: Codable {
    var gamesPlayed = 0
    var gamesWon = 0
    var currentStreak = 0
    var bestStreak = 0
    var suecasMade = 0
    var matchesPlayed = 0
    var matchesWon = 0

    init() {}

    /// Missing keys fall back to zero so stats saved by older versions still load.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        gamesPlayed = try c.decodeIfPresent(Int.self, forKey: .gamesPlayed) ?? 0
        gamesWon = try c.decodeIfPresent(Int.self, forKey: .gamesWon) ?? 0
        currentStreak = try c.decodeIfPresent(Int.self, forKey: .currentStreak) ?? 0
        bestStreak = try c.decodeIfPresent(Int.self, forKey: .bestStreak) ?? 0
        suecasMade = try c.decodeIfPresent(Int.self, forKey: .suecasMade) ?? 0
        matchesPlayed = try c.decodeIfPresent(Int.self, forKey: .matchesPlayed) ?? 0
        matchesWon = try c.decodeIfPresent(Int.self, forKey: .matchesWon) ?? 0
    }
}

@MainActor
final class MatchStatsStore: ObservableObject {
    static let shared = MatchStatsStore()

    @Published private(set) var stats: MatchStats

    private static let storageKey = "app.matchStats"

    private init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode(MatchStats.self, from: data) {
            stats = decoded
        } else {
            stats = MatchStats()
        }
    }

    /// `suecaByHuman` counts only suecas made by the player's team.
    func recordHandResult(humanTeamWon: Bool, suecaByHuman: Bool) {
        stats.gamesPlayed += 1
        if humanTeamWon {
            stats.gamesWon += 1
            stats.currentStreak += 1
            stats.bestStreak = max(stats.bestStreak, stats.currentStreak)
        } else {
            stats.currentStreak = 0
        }
        if suecaByHuman { stats.suecasMade += 1 }
        persist()
    }

    func recordMatchResult(humanTeamWon: Bool) {
        stats.matchesPlayed += 1
        if humanTeamWon { stats.matchesWon += 1 }
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}
