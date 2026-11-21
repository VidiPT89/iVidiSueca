# 🎴 iVidiSueca

> The classic Portuguese trick-taking card game Sueca, natively reimagined for iOS with SwiftUI.

[Report Bug](https://github.com/VidiPT89/iVidiSueca/issues) · [Request Feature](https://github.com/VidiPT89/iVidiSueca/issues)

## ✨ Features

- ✅ Official Sueca rules — 40-card deck, 4 players in 2 partnerships, mandatory follow-suit, free cut or discard when void
- ✅ Optional mandatory-cut house rule (Settings)
- ✅ Full matches — hands score 1, 2 or 4 games (61+, 91+, Sueca); first team to 4 games wins
- ✅ 1 human player + 3 bot opponents, with 3 selectable bot difficulty levels (Easy, Medium, Hard)
- ✅ Card-counting bot on Hard difficulty — tracks played cards to spot master cards and safe cuts
- ✅ Smooth, native SwiftUI animations — dealing, card play, trick collection and score count-up
- ✅ Haptic feedback on card play; unavailable cards shake and explain why when tapped
- ✅ Felt table, readable two-row hand, illustrated court cards and live score progress
- ✅ Contextual follow-suit guidance, legal-card controls and optional hints
- ✅ Pause/resume, automatic pause when leaving the app, and safe return to menu
- ✅ Live scoreboard with visible trump card and turn indicator
- ✅ Runtime language switch — Português (PT-PT) and English, independent of system locale
- ✅ Dark mode, Light mode, and System mode
- ✅ Custom color identity inspired by [ividi.dev](https://ividi.dev/) — burnt orange, amber and near-black
- ✅ In-app rules reference and statistics — hands, matches, best streak and suecas

## 🛠️ Tech Stack

| Category    | Technology            |
|-------------|------------------------|
| Language    | Swift 5.9+              |
| UI          | SwiftUI (iOS 16+)        |
| Architecture| MVVM                     |
| Project     | XcodeGen                 |

## 🚀 Quick Start

**Prerequisites**
- Xcode 15+
- iOS 16+ simulator or device

**Steps**

```bash
git clone https://github.com/VidiPT89/iVidiSueca.git
cd iVidiSueca
open iVidiSueca.xcodeproj
```

Select the `iVidiSueca` scheme and run on a simulator or device.

## 📖 Usage

Launch the app, tap Play, and take on 3 bot opponents in a match of Sueca. Your partner sits opposite
you; win tricks together to pass 60 of the 120 points in play. Each hand won adds 1 game (2 with more than
90 points, 4 for a Sueca), and the first team to 4 games takes the match. Adjust bot difficulty and speed, switch
language and appearance, and review the rules at any time from Settings and the main menu.

## 🧪 Testing

Run the engine regression suite (rules, scoring, targeted bot decisions and 300 complete hands under both cut rules):

```bash
sh scripts/test-engine.sh
```

The `iVidiSuecaUITests` target checks all ten cards and player seats remain on screen,
plays a complete hand (including a rejected tap on an unavailable card), deals the next hand,
and exercises pause, resume, exit confirmation and restart.
Run it with Product → Test in Xcode on an iPhone or iPad simulator.

The Xcode project is generated from `project.yml`; after adding or removing files run `xcodegen generate`.

Build and run the `iVidiSueca` scheme in Xcode (`⌘R`), or verify the project compiles via:

```bash
xcodebuild -project iVidiSueca.xcodeproj -scheme iVidiSueca -destination 'generic/platform=iOS Simulator' build
```

## 📄 License

Distributed under the MIT License. See [LICENSE](LICENSE) for details.

## 👨‍💻 Author

**David Arsénio Martins**

🌐 Website: [ividi.dev](https://ividi.dev/)
🐙 GitHub: [@VidiPT89](https://github.com/VidiPT89/)

## 🤝 Contributing

Contributions, issues and feature requests are welcome. Feel free to check the [issues page](https://github.com/VidiPT89/iVidiSueca/issues).

---

<p align="center">Developed by <a href="https://ividi.dev">David Arsénio Martins</a></p>
<p align="center">If you like this project, consider giving it a ⭐</p>
