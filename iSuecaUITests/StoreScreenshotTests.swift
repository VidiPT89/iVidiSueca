import XCTest

/// Captures App Store screenshots as test attachments. Skipped unless the runner gets
/// `STORE_SHOTS=1` (pass `TEST_RUNNER_STORE_SHOTS=1` to xcodebuild); export them from the
/// result bundle with `xcrun xcresulttool export attachments`.
final class StoreScreenshotTests: XCTestCase {
    override func setUpWithError() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["STORE_SHOTS"] == "1", "Store screenshots only on demand")
        continueAfterFailure = false
    }

    func testPortugueseScreenshots() { capture(language: "pt-PT", playable: "Jogável", following: ["Segue", "Não tens"]) }

    func testEnglishScreenshots() { capture(language: "en", playable: "Playable", following: ["Follow", "You have no"]) }

    /// `following` are status prefixes shown when the player responds to cards already on the table.
    private func capture(language: String, playable: String, following: [String]) {
        let app = XCUIApplication()
        // An empty stats value overrides what earlier runs saved, so the menu starts clean.
        app.launchArguments += ["-app.language.override", language, "-app.aiSpeed", "fast", "-app.matchStats", ""]
        app.launch()

        let play = app.buttons["menu.play"]
        XCTAssertTrue(play.waitForExistence(timeout: 10))
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "isHittable == true"), object: play)], timeout: 8), .completed)
        snap(app, "3-menu", language)

        app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", language == "en" ? "Rules" : "Regras")).firstMatch.tap()
        sleep(1)
        snap(app, "4-rules", language)
        app.navigationBars.buttons.firstMatch.tap()
        sleep(1)

        play.tap()
        let cards = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'hand.card.'"))
        let playableCard = cards.matching(NSPredicate(format: "isEnabled == true AND value == %@", playable)).firstMatch
        let status = app.descendants(matching: .any)["game.status"]
        var tableShot = false
        for trick in 1...10 {
            XCTAssertTrue(playableCard.waitForExistence(timeout: 30))
            sleep(1)
            // A trick in progress, with cards on the felt and the hint outline, makes the clearest table shot.
            if !tableShot, trick >= 2, following.contains(where: { status.label.contains($0) }) {
                app.buttons["game.hint"].tap()
                sleep(1)
                snap(app, "1-table", language)
                tableShot = true
            }
            playableCard.tap()
        }
        XCTAssertTrue(tableShot)

        XCTAssertTrue(app.buttons["game.playAgain"].waitForExistence(timeout: 30))
        sleep(2)
        snap(app, "2-end", language)
    }

    private func snap(_ app: XCUIApplication, _ name: String, _ language: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "\(language)-\(name)"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
