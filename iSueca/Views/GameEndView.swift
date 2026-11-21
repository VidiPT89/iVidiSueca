import SwiftUI

struct GameEndView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var appear = false

    private var result: HandResult? { viewModel.handResult }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.brandBackground, Color.brandSurface], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 22) {
                    Image(systemName: trophyIcon)
                        .font(.system(size: 64))
                        .foregroundStyle(LinearGradient(colors: [.brandPrimary, .brandSecondary], startPoint: .top, endPoint: .bottom))
                        .scaleEffect(appear ? 1 : 0.5)
                        .opacity(appear ? 1 : 0)
                        .accessibilityHidden(true)
                        .padding(.top, 24)

                    Text(resultTitle)
                        .font(.title.weight(.heavy))
                        .foregroundColor(.brandTextPrimary)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("end.title")

                    if result?.wasSueca == true {
                        Text(L.t("game.sueca"))
                            .font(.headline)
                            .foregroundColor(.brandSecondary)
                            .multilineTextAlignment(.center)
                    }

                    HStack(spacing: 30) {
                        scoreColumn(.teamA, value: result?.teamAPoints ?? 0)
                        scoreColumn(.teamB, value: result?.teamBPoints ?? 0)
                    }

                    if let result {
                        Text(L.t("end.handWorth.\(result.gamesAwarded)"))
                            .font(.subheadline)
                            .foregroundColor(.brandTextSecondary)
                            .multilineTextAlignment(.center)
                    }

                    matchCard
                        .padding(.top, 4)

                    VStack(spacing: 14) {
                        Button {
                            viewModel.continueAfterHand()
                        } label: {
                            Text(L.t(viewModel.isMatchOver ? "end.newMatch" : "end.nextHand"))
                                .font(.headline.weight(.bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: 260)
                                .padding(.vertical, 16)
                                .background(
                                    Capsule().fill(LinearGradient(colors: [.brandPrimary, .brandSecondary], startPoint: .leading, endPoint: .trailing))
                                )
                                .shadow(color: Color.brandPrimary.opacity(0.4), radius: 14, y: 6)
                        }
                        .accessibilityIdentifier("game.playAgain")

                        Button {
                            viewModel.returnToMenu()
                        } label: {
                            Text(L.t("game.leave"))
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.brandTextSecondary)
                                .frame(minHeight: 44)
                        }
                        .accessibilityIdentifier("end.menu")
                    }
                    .padding(.top, 12)
                }
                .padding()
                // Centred on tall screens, scrollable on short ones.
                .frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) { appear = true }
        }
    }

    private var matchCard: some View {
        VStack(spacing: 8) {
            Text(String(format: L.t("end.matchScore"), ScoreCalculator.gamesToWinMatch))
                .font(.caption.weight(.semibold))
                .foregroundColor(.brandTextSecondary)
                .textCase(.uppercase)
            HStack(spacing: 18) {
                gamePips(viewModel.teamAGames, color: .brandPrimary)
                Text("\(viewModel.teamAGames) – \(viewModel.teamBGames)")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.brandTextPrimary)
                gamePips(viewModel.teamBGames, color: .brandTextSecondary)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 22)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.brandSurface))
        .accessibilityElement(children: .combine)
    }

    /// One dot per game needed to win the match, filled as games are won.
    private func gamePips(_ games: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            ForEach(0..<ScoreCalculator.gamesToWinMatch, id: \.self) { index in
                Circle()
                    .fill(index < games ? color : color.opacity(0.18))
                    .frame(width: 8, height: 8)
            }
        }
        .accessibilityHidden(true)
    }

    private var trophyIcon: String {
        if let matchWinner = result?.matchWinner {
            return matchWinner == .teamA ? "trophy.fill" : "flag.fill"
        }
        return result?.winner == .teamA ? "star.fill" : "star"
    }

    private var resultTitle: String {
        if let matchWinner = result?.matchWinner {
            return L.t(matchWinner == .teamA ? "end.matchWon" : "end.matchLost")
        }
        switch result?.winner {
        case .teamA: return L.t("game.youWin")
        case .teamB: return L.t("game.youLose")
        case nil: return L.t("game.draw")
        }
    }

    private func scoreColumn(_ team: Team, value: Int) -> some View {
        VStack(spacing: 4) {
            Text(L.t(team.nameKey))
                .font(.caption.weight(.semibold))
                .foregroundColor(.brandTextSecondary)
            Text("\(value)")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundColor(.brandTextPrimary)
        }
        .accessibilityElement(children: .combine)
    }
}
