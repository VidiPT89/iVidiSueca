import SwiftUI

struct ScoreboardView: View {
    let teamAPoints: Int
    let teamBPoints: Int
    let trumpCard: Card?

    var body: some View {
        HStack(spacing: 14) {
            score(.teamA, points: teamAPoints, color: .brandPrimary)
            if let trumpCard {
                VStack(spacing: 4) {
                    Text(L.t("game.trump"))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.brandTextSecondary)
                    CardView(card: trumpCard, width: 32)
                }
                .accessibilityElement(children: .combine)
            }
            score(.teamB, points: teamBPoints, color: .brandTextSecondary)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.brandSurface))
        .frame(maxWidth: 620)
    }

    private func score(_ team: Team, points: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(L.t(team.nameKey))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.brandTextSecondary)
                .lineLimit(1).minimumScaleFactor(0.7)
            Text("\(points)")
                .font(.system(size: 30, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Color.brandTextPrimary)
            GeometryReader { geo in
                Capsule().fill(color.opacity(0.12))
                Capsule().fill(color)
                    .frame(width: geo.size.width * min(CGFloat(points) / CGFloat(ScoreCalculator.winThreshold), 1))
            }
            .frame(height: 3)
            .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
