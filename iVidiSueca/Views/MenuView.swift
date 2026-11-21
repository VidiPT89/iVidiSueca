import SwiftUI

struct MenuView: View {
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject private var statsStore = MatchStatsStore.shared
    @ObservedObject private var localization = LocalizationManager.shared
    @State private var showSettings = false
    @State private var showAbout = false
    @State private var showRules = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.brandBackground, Color.brandSurface.opacity(0.6)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
              VStack(spacing: 20) {
                HStack {
                    Spacer()
                    languageToggle
                }
                .padding(.horizontal)
                .padding(.top, 6)

                ZStack {
                    ForEach(Array(Suit.allCases.enumerated()), id: \.offset) { index, suit in
                        CardView(card: Card(suit: suit, rank: .ace), width: 82)
                            .rotationEffect(.degrees(Double(index) * 15 - 22.5))
                            .offset(x: CGFloat(index) * 38 - 57, y: abs(CGFloat(index) - 1.5) * 12)
                    }
                }
                .frame(height: 150)
                .accessibilityHidden(true)
                .padding(.top, 16)

                titleBlock

                Button {
                    viewModel.startNewMatch()
                } label: {
                    Label(L.t("menu.startGame"), systemImage: "play.fill")
                        .font(.headline.weight(.bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: 320)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16).fill(Color.brandPrimary)
                        )
                        .shadow(color: Color.brandPrimary.opacity(0.4), radius: 14, y: 6)
                }
                .accessibilityIdentifier("menu.play")

                VStack(spacing: 12) {
                    menuButton(L.t("menu.rules"), icon: "book.closed.fill") { showRules = true }
                    menuButton(L.t("menu.settings"), icon: "gearshape.fill") { showSettings = true }
                    menuButton(L.t("menu.about"), icon: "info.circle.fill") { showAbout = true }
                }
                .padding(.top, 4)

                Text(L.t("menu.tagline"))
                    .font(.caption).foregroundStyle(Color.brandTextSecondary)
                    .padding(.top, 8)
              }
              .frame(maxWidth: 480)
              .padding(24)
              .frame(maxWidth: .infinity)
            }
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showAbout) { AboutView() }
        .sheet(isPresented: $showRules) { RulesView() }
    }

    private var languageToggle: some View {
        Button {
            localization.language = localization.language == .portuguese ? .english : .portuguese
        } label: {
            Text(localization.language == .portuguese ? "PT" : "EN")
                .font(.caption.weight(.bold))
                .foregroundColor(.brandPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.brandSurface))
        }
    }

    private var titleBlock: some View {
        VStack(spacing: 6) {
            Text(L.t("menu.title"))
                .font(.system(size: 54, weight: .bold, design: .serif))
                .tracking(1)
                .foregroundStyle(
                    LinearGradient(colors: [.brandPrimary, .brandSecondary], startPoint: .leading, endPoint: .trailing)
                )
                .shadow(color: Color.brandPrimary.opacity(0.25), radius: 12, y: 4)
            Text(L.t("menu.subtitle"))
                .font(.subheadline)
                .foregroundColor(.brandTextSecondary)
                .multilineTextAlignment(.center)

            if statsStore.stats.gamesPlayed > 0 {
                statsPanel.padding(.top, 10)
            }
        }
    }

    private var statsPanel: some View {
        let stats = statsStore.stats
        return VStack(spacing: 10) {
            Text(String(format: L.t("stats.record"), stats.gamesWon, stats.gamesPlayed))
                .font(.footnote.weight(.semibold))
            HStack(spacing: 0) {
                statItem("\(stats.matchesWon)/\(stats.matchesPlayed)", L.t("stats.matches"))
                statItem("\(stats.bestStreak)", L.t("stats.bestStreak"))
                statItem("\(stats.suecasMade)", L.t("stats.suecas"))
            }
        }
        .foregroundColor(.brandTextSecondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: 320)
        .background(
            RoundedRectangle(cornerRadius: 16).fill(Color.brandSurface)
                .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
        )
        .accessibilityElement(children: .combine)
    }

    private func statItem(_ value: String, _ title: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundColor(.brandTextPrimary)
            Text(title)
                .font(.caption2)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }

    private func menuButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.brandPrimary.opacity(0.14))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .foregroundColor(.brandPrimary)
                        .font(.subheadline.weight(.semibold))
                }
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.brandTextSecondary.opacity(0.6))
            }
            .font(.subheadline.weight(.medium))
            .foregroundColor(.brandTextPrimary)
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.brandSurface)
                    .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
            )
        }
        .frame(maxWidth: 320)
    }
}
