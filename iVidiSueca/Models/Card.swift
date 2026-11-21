import Foundation

enum Suit: String, CaseIterable, Identifiable {
    case clubs, hearts, spades, diamonds

    var id: String { rawValue }

    var isRed: Bool {
        self == .hearts || self == .diamonds
    }

    var nameKey: String { "suit.\(rawValue)" }
}

enum Rank: Int, CaseIterable, Comparable {
    case two = 2, three, four, five, six, queen, jack, king, seven, ace
    // Enum order reflects trick-taking STRENGTH (weak -> strong), not face value.

    static func < (lhs: Rank, rhs: Rank) -> Bool { lhs.rawValue < rhs.rawValue }

    var label: String {
        switch self {
        case .ace: return "A"
        case .seven: return "7"
        case .king: return "K"
        case .jack: return "J"
        case .queen: return "Q"
        case .six: return "6"
        case .five: return "5"
        case .four: return "4"
        case .three: return "3"
        case .two: return "2"
        }
    }

    var pointValue: Int {
        switch self {
        case .ace: return 11
        case .seven: return 10
        case .king: return 4
        case .jack: return 3
        case .queen: return 2
        default: return 0
        }
    }
}

struct Card: Identifiable, Hashable {
    let id = UUID()
    let suit: Suit
    let rank: Rank

    var pointValue: Int { rank.pointValue }

    /// True for cards worth 10 or 11 points, which bots avoid throwing away.
    var isHighValue: Bool { rank == .ace || rank == .seven }
}
