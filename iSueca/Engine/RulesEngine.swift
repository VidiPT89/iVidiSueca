import Foundation

enum RulesEngine {
    /// Cards a player is legally allowed to play, given the current trick and trump.
    ///
    /// Official Sueca only obliges a player to follow the suit led; a player without it may
    /// cut or discard freely. `forcedCut` enables the common house rule where a player
    /// without the suit led must play a trump if they hold one.
    static func legalMoves(hand: [Card], trick: Trick, trump: Suit, forcedCut: Bool = false) -> [Card] {
        guard let leadSuit = trick.leadSuit else {
            return hand
        }

        let sameSuit = hand.filter { $0.suit == leadSuit }
        if !sameSuit.isEmpty {
            return sameSuit
        }

        if forcedCut {
            let trumps = hand.filter { $0.suit == trump }
            if !trumps.isEmpty {
                return trumps
            }
        }

        return hand
    }
}
