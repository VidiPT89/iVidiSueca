import SwiftUI

struct RootView: View {
    @StateObject private var viewModel = GameViewModel()
    @EnvironmentObject private var settings: SettingsViewModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var showSplash = true

    var body: some View {
        ZStack {
            Group {
                switch viewModel.phase {
                case .menu:
                    MenuView(viewModel: viewModel)
                case .dealing, .playing, .trickEnd:
                    GameView(viewModel: viewModel)
                case .handEnd:
                    GameEndView(viewModel: viewModel)
                }
            }
            .allowsHitTesting(!showSplash)
            .accessibilityHidden(showSplash)
            .animation(.easeInOut(duration: 0.35), value: viewModel.phase)
            .transition(.opacity)

            if showSplash {
                SplashView { withAnimation(.easeInOut(duration: 0.4)) { showSplash = false } }
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onChange(of: scenePhase) { phase in
            if phase != .active && viewModel.phase != .menu && viewModel.phase != .handEnd {
                viewModel.setPaused(true)
            }
        }
        .preferredColorScheme(settings.theme.colorScheme)
        .onAppear {
            viewModel.configure(settings: settings)
        }
    }
}
