import SwiftUI

struct GameView: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showHistory = false
    @State private var showRules = false
    @State private var showExitConfirmation = false
    @State private var hintID: UUID?

    private var humanTurn: Bool {
        viewModel.phase == .playing && viewModel.currentPlayerTurn == .south
    }

    var body: some View {
        GeometryReader { proxy in
            let compact = proxy.size.height < 650
            VStack(spacing: compact ? 8 : 16) {
                toolbar
                ScoreboardView(teamAPoints: viewModel.teamAPoints, teamBPoints: viewModel.teamBPoints,
                               trumpCard: viewModel.trumpCard)
                HStack {
                    Text(String(format: L.t("game.round"), min(viewModel.completedTricks.count + (viewModel.phase == .trickEnd ? 0 : 1), 10)))
                    Spacer()
                    Text(L.t("game.target"))
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.brandTextSecondary)
                .padding(.horizontal, 6)

                table(compact: compact)
                    .frame(maxWidth: 760)
                    .frame(maxHeight: .infinity)

                VStack(spacing: 6) {
                    Text(statusTitle)
                        .font(.headline)
                        .foregroundStyle(Color.brandTextPrimary)
                    Text(statusDetail)
                        .font(.caption)
                        .foregroundStyle(Color.brandTextSecondary)
                        .multilineTextAlignment(.center)
                        .frame(minHeight: 28)
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("game.status")

                humanHand(width: min(proxy.size.width - 24, 620), compact: compact)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(width: proxy.size.width, height: proxy.size.height)
            .background(Color.brandBackground.ignoresSafeArea())
            .overlay {
                if let stage = viewModel.dealingStage {
                    DealingOverlayView(stage: stage, trumpCard: viewModel.trumpCard,
                                       leaderNameKey: viewModel.currentPlayerTurn.nameKey)
                }
            }
            .overlay {
                if viewModel.isPaused && !showHistory && !showRules {
                    pauseOverlay
                }
            }
        }
        .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.82), value: viewModel.currentTrick.cardsPlayed.count)
        .onChange(of: viewModel.currentTrick.cardsPlayed.count) { _ in hintID = nil }
        .sheet(isPresented: $showHistory, onDismiss: { viewModel.setPaused(false) }) {
            TrickHistoryView(tricks: viewModel.completedTricks)
        }
        .sheet(isPresented: $showRules, onDismiss: { viewModel.setPaused(false) }) { RulesView() }
        .confirmationDialog(L.t("game.leaveTitle"), isPresented: $showExitConfirmation, titleVisibility: .visible) {
            Button(L.t("game.leave"), role: .destructive) { viewModel.returnToMenu() }
                .accessibilityIdentifier("game.confirmLeave")
            Button(L.t("game.cancel"), role: .cancel) { }
        } message: { Text(L.t("game.leaveMessage")) }
    }

    private var toolbar: some View {
        HStack {
            Button { viewModel.setPaused(true) } label: {
                Image(systemName: "pause.fill").frame(width: 44, height: 44)
            }
            .accessibilityLabel(L.t("game.pause"))
            .accessibilityIdentifier("game.pause")
            Spacer()
            Text("SUECA").font(.system(.subheadline, design: .serif).weight(.bold)).tracking(4)
            Spacer()
            Button {
                viewModel.setPaused(true)
                showHistory = true
            } label: {
                Image(systemName: "clock.arrow.circlepath").frame(width: 44, height: 44)
            }
            .accessibilityLabel(L.t("history.title"))
            .accessibilityIdentifier("game.history")
        }
        .foregroundStyle(Color.brandTextPrimary)
        .frame(height: 36)
    }

    private func table(compact: Bool) -> some View {
        GeometryReader { geo in
            let cardWidth = min(compact ? 48.0 : (geo.size.width > 600 ? 90.0 : 64.0), geo.size.width * 0.16)
            ZStack {
                RoundedRectangle(cornerRadius: 36)
                    .fill(RadialGradient(colors: [Color(red: 0.12, green: 0.32, blue: 0.28), Color(red: 0.035, green: 0.15, blue: 0.13)], center: .center, startRadius: 10, endRadius: geo.size.width * 0.8))
                TableGrain().stroke(.white.opacity(0.035), lineWidth: 0.5)
                    .clipShape(RoundedRectangle(cornerRadius: 36))
                RoundedRectangle(cornerRadius: 30)
                    .strokeBorder(Color(red: 0.78, green: 0.64, blue: 0.39).opacity(0.4), lineWidth: 1)
                    .padding(6)
                if viewModel.currentTrick.cardsPlayed.isEmpty {
                    VStack(spacing: 5) {
                        Image(systemName: "suit.spade").font(.system(size: 30, weight: .ultraLight))
                        Text("iSueca").font(.system(.title3, design: .serif)).tracking(2)
                    }
                    .foregroundStyle(.white.opacity(0.18))
                }
                seat(.north).frame(maxHeight: .infinity, alignment: .top).padding(.top, 12)
                seat(.west).frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 12)
                seat(.east).frame(maxWidth: .infinity, alignment: .trailing).padding(.trailing, 12)
                ForEach(viewModel.currentTrick.cardsPlayed) { played in
                    let winning = viewModel.phase == .trickEnd && viewModel.lastTrickWinner == played.position
                    CardView(card: played.card, width: cardWidth)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(winning ? Color.brandSecondary : .clear, lineWidth: 3))
                        .rotationEffect(.degrees(played.position == .west ? -9 : played.position == .east ? 9 : 0))
                        .offset(cardOffset(played.position, width: cardWidth))
                        .transition(.opacity.combined(with: .scale(scale: reduceMotion ? 1 : 0.8)))
                }
                HStack(spacing: 4) {
                    Image(systemName: "rectangle.stack")
                    Text("\(viewModel.currentTrick.points) \(L.t("history.points"))")
                        .monospacedDigit()
                }
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white.opacity(0.7))
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 12)
            }
        }
        .frame(minHeight: compact ? 195 : 240)
    }

    private func seat(_ position: PlayerPosition) -> some View {
        let active = viewModel.currentPlayerTurn == position && viewModel.phase == .playing
        let layout = position == .north ? AnyLayout(HStackLayout(spacing: 6)) : AnyLayout(VStackLayout(spacing: 4))
        return layout {
            Image(systemName: position == .north ? "person.crop.circle.fill" : "person.crop.circle")
                .font(.system(size: 22))
            Text(L.t(position.nameKey)).font(.caption2.weight(.semibold))
                .lineLimit(1).minimumScaleFactor(0.8)
            Text("\(viewModel.handsByPosition[position]?.count ?? 0)")
                .font(.caption2.monospacedDigit())
                .opacity(0.7)
        }
        .foregroundStyle(active ? Color.brandSecondary : .white.opacity(0.8))
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 12).fill(active ? .white.opacity(0.1) : .clear))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(active ? Color.brandSecondary.opacity(0.65) : .clear))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("seat.\(position.rawValue)")
    }

    private func cardOffset(_ position: PlayerPosition, width: CGFloat) -> CGSize {
        switch position {
        case .north: return CGSize(width: 0, height: -width * 0.55)
        case .south: return CGSize(width: 0, height: width * 0.55)
        case .west: return CGSize(width: -width * 0.8, height: 0)
        case .east: return CGSize(width: width * 0.8, height: 0)
        }
    }

    private var statusTitle: String {
        if viewModel.phase == .trickEnd, let winner = viewModel.lastTrickWinner {
            return String(format: L.t("game.trickWinner"), L.t(winner.nameKey), viewModel.currentTrick.points)
        }
        return humanTurn ? L.t("game.yourTurn") : String(format: L.t("game.thinking"), L.t(viewModel.currentPlayerTurn.nameKey))
    }

    private var statusDetail: String {
        if viewModel.phase == .trickEnd { return L.t("game.nextTrick") }
        guard humanTurn else { return L.t("game.partnerInfo") }
        if hintID != nil { return L.t("game.hintDetail") }
        if let lead = viewModel.currentTrick.leadSuit {
            if (viewModel.handsByPosition[.south] ?? []).contains(where: { $0.suit == lead }) {
                return String(format: L.t("game.follow"), L.t(lead.nameKey))
            }
            if viewModel.humanLegalMoves.allSatisfy({ $0.suit == viewModel.trumpSuit }) {
                return String(format: L.t("game.cut"), L.t(viewModel.trumpSuit.nameKey))
            }
        }
        return L.t("game.choose")
    }

    private func humanHand(width: CGFloat, compact: Bool) -> some View {
        let cards = viewModel.handsByPosition[.south] ?? []
        let legal = Set(viewModel.humanLegalMoves.map(\.id))
        let cardWidth = min(compact ? 51 : (width > 500 ? 96 : 66), (width - 32) / 5)
        return VStack(spacing: 8) {
            HStack {
                Text(L.t("game.yourHand")).font(.caption.weight(.semibold))
                Spacer()
                Button {
                    hintID = viewModel.suggestedCard?.id
                } label: {
                    Label(L.t("game.hint"), systemImage: "lightbulb")
                        .font(.caption.weight(.semibold))
                        .frame(minHeight: 32)
                }
                .disabled(!humanTurn)
                .accessibilityIdentifier("game.hint")
            }
            .foregroundStyle(Color.brandTextSecondary)
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(cardWidth), spacing: 8), count: 5), spacing: 8) {
                ForEach(cards) { card in
                    Button {
                        viewModel.playHumanCard(card)
                    } label: {
                        CardView(card: card, width: cardWidth)
                            .overlay(RoundedRectangle(cornerRadius: cardWidth * 0.14)
                                .stroke(hintID == card.id ? Color.brandSecondary : .clear, lineWidth: 3))
                            .opacity(humanTurn && !legal.contains(card.id) ? 0.65 : 1)
                    }
                    .buttonStyle(HandCardButtonStyle())
                    .disabled(!humanTurn || !legal.contains(card.id))
                    .accessibilityLabel("\(card.displayLabel), \(L.t(card.suit.nameKey)), \(card.pointValue) \(L.t("history.points"))")
                    .accessibilityIdentifier("hand.card.\(card.suit.rawValue).\(card.rank.rawValue)")
                }
            }
            .frame(height: cardWidth * 1.38 * 2 + 8, alignment: .top)
        }
        .frame(maxWidth: 620)
    }

    private var pauseOverlay: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "pause.circle").font(.system(size: 44, weight: .light)).foregroundStyle(Color.brandPrimary)
                Text(L.t("game.paused")).font(.title2.bold())
                Button(L.t("game.resume")) { viewModel.setPaused(false) }
                    .buttonStyle(.borderedProminent).tint(.brandPrimary)
                    .accessibilityIdentifier("game.resume")
                Button(L.t("menu.rules")) { showRules = true }
                Button(L.t("game.leave"), role: .destructive) { showExitConfirmation = true }
                    .accessibilityIdentifier("game.leave")
            }
            .padding(32)
            .frame(maxWidth: 300)
            .background(RoundedRectangle(cornerRadius: 24).fill(Color.brandSurface))
            .foregroundStyle(Color.brandTextPrimary)
        }
        .accessibilityAddTraits(.isModal)
    }
}

private struct TableGrain: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        for x in stride(from: 0.0, through: rect.width, by: 6) {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: rect.height))
        }
        for y in stride(from: 0.0, through: rect.height, by: 6) {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y))
        }
        return path
    }
}

/// Keep unavailable cards readable; the system plain style also dims disabled labels.
private struct HandCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}
