import SwiftUI

struct CardView: View {
    let card: Card
    var width: CGFloat = 58

    private var height: CGFloat { width * 1.38 }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: width * 0.14)
                .fill(LinearGradient(colors: [Color.white, Color(white: 0.94)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    RoundedRectangle(cornerRadius: width * 0.14)
                        .strokeBorder(Color.black.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 5, y: 3)

            // Faint diagonal sheen so the white card face doesn't look like a flat sticker.
            RoundedRectangle(cornerRadius: width * 0.14)
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.55), .clear, .black.opacity(0.04)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )

            if [.king, .queen, .jack].contains(card.rank) {
                VStack(spacing: width * 0.02) {
                    Image(systemName: card.rank == .king ? "crown.fill" : card.rank == .queen ? "crown" : "shield.lefthalf.filled")
                        .font(.system(size: width * 0.28, weight: .light))
                    Image(systemName: suitSystemImage).font(.system(size: width * 0.2))
                }
                .foregroundStyle(suitGradient)
            } else {
                Image(systemName: suitSystemImage)
                    .font(.system(size: width * (card.rank == .ace ? 0.42 : 0.32)))
                    .foregroundStyle(suitGradient)
            }
            VStack {
                HStack { pip; Spacer() }
                Spacer()
                HStack { Spacer(); pip.rotationEffect(.degrees(180)) }
            }
            .padding(width * 0.09)
        }
        .frame(width: width, height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(card.rank.label), \(L.t(card.suit.nameKey))")
    }

    private var pip: some View {
        VStack(spacing: 0) {
            Text(card.rank.label)
                .font(.system(size: width * 0.25, weight: .bold, design: .serif))
            Image(systemName: suitSystemImage)
                .font(.system(size: width * 0.15))
        }
        .foregroundColor(suitColor)
    }

    private var suitColor: Color {
        card.suit.isRed ? Color(red: 0.75, green: 0.15, blue: 0.15) : Color(red: 0.12, green: 0.12, blue: 0.14)
    }

    private var suitGradient: LinearGradient {
        LinearGradient(colors: [suitColor, suitColor.opacity(0.75)], startPoint: .top, endPoint: .bottom)
    }

    private var suitSystemImage: String {
        switch card.suit {
        case .clubs: return "suit.club.fill"
        case .hearts: return "suit.heart.fill"
        case .spades: return "suit.spade.fill"
        case .diamonds: return "suit.diamond.fill"
        }
    }
}
