import Foundation
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var theme: AppTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: Self.themeKey) }
    }

    @Published var aiDifficulty: AIDifficulty {
        didSet { UserDefaults.standard.set(aiDifficulty.rawValue, forKey: Self.difficultyKey) }
    }

    @Published var aiSpeed: AISpeed {
        didSet { UserDefaults.standard.set(aiSpeed.rawValue, forKey: Self.aiSpeedKey) }
    }

    @Published var soundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(soundEnabled, forKey: Self.soundEnabledKey)
            SoundPlayer.isEnabled = soundEnabled
        }
    }

    /// House rule: a player without the suit led must play a trump if they have one.
    @Published var forcedCut: Bool {
        didSet { UserDefaults.standard.set(forcedCut, forKey: Self.forcedCutKey) }
    }

    private static let themeKey = "app.theme"
    private static let difficultyKey = "app.aiDifficulty"
    private static let aiSpeedKey = "app.aiSpeed"
    private static let soundEnabledKey = "app.soundEnabled"
    private static let forcedCutKey = "app.forcedCut"

    init() {
        let defaults = UserDefaults.standard
        theme = AppTheme(rawValue: defaults.string(forKey: Self.themeKey) ?? "") ?? .system
        aiDifficulty = AIDifficulty(rawValue: defaults.string(forKey: Self.difficultyKey) ?? "") ?? .normal
        aiSpeed = AISpeed(rawValue: defaults.string(forKey: Self.aiSpeedKey) ?? "") ?? .normal
        soundEnabled = defaults.object(forKey: Self.soundEnabledKey) as? Bool ?? true
        forcedCut = defaults.bool(forKey: Self.forcedCutKey)
        SoundPlayer.isEnabled = soundEnabled
    }
}
