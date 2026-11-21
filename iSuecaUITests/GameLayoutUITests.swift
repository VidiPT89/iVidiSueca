import XCTest

final class GameLayoutUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    private func startGame(_ app: XCUIApplication) {
        // Pin the language so accessibility values such as "Playable" are predictable.
        app.launchArguments += ["-app.language.override", "en"]
        app.launch()
        let play = app.buttons["menu.play"]
        XCTAssertTrue(play.waitForExistence(timeout: 10))
        let ready = NSPredicate(format: "isHittable == true")
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: ready, object: play)], timeout: 8), .completed)
        play.tap()
        if !app.buttons["game.hint"].waitForExistence(timeout: 3), play.exists {
            play.tap()
        }
        XCTAssertTrue(app.buttons["game.hint"].waitForExistence(timeout: 10))
        let turn = NSPredicate(format: "isEnabled == true")
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: turn, object: app.buttons["game.hint"])], timeout: 15), .completed)
    }

    func testFullHandLayoutAndCompleteGame() {
        let app = XCUIApplication()
        startGame(app)
        let cards = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'hand.card.'"))
        XCTAssertEqual(cards.count, 10)
        for card in cards.allElementsBoundByIndex {
            XCTAssertTrue(app.frame.contains(card.frame), "Card outside screen: \(card.identifier)")
        }
        for seat in [1, 2, 3] {
            let element = app.descendants(matching: .any).matching(identifier: "seat.\(seat)").firstMatch
            XCTAssertTrue(element.exists)
            XCTAssertTrue(app.frame.contains(element.frame))
        }
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Full-hand-table"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        app.buttons["game.hint"].tap()
        XCTAssertEqual(cards.count, 10, "Hint must not play a card")
        var checkedRejection = false
        for remaining in stride(from: 10, through: 1, by: -1) {
            let playable = cards.matching(NSPredicate(format: "isEnabled == true AND value == 'Playable'")).firstMatch
            XCTAssertTrue(playable.waitForExistence(timeout: 20))
            XCTAssertEqual(cards.count, remaining)
            let unavailable = cards.matching(NSPredicate(format: "value == 'Unavailable'")).firstMatch
            if !checkedRejection, unavailable.exists {
                unavailable.tap()
                XCTAssertEqual(cards.count, remaining, "An unavailable card must not be played")
                checkedRejection = true
            }
            playable.tap()
        }
        let next = app.buttons["game.playAgain"]
        XCTAssertTrue(next.waitForExistence(timeout: 20))
        let endScreen = XCTAttachment(screenshot: app.screenshot())
        endScreen.name = "Hand-end"
        endScreen.lifetime = .keepAlways
        add(endScreen)

        // The match continues (or restarts) with a fresh deal.
        next.tap()
        XCTAssertTrue(app.buttons["game.hint"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["game.matchScore"].exists)
    }

    func testPauseExitAndRestart() {
        let app = XCUIApplication()
        startGame(app)
        app.buttons["game.pause"].tap()
        XCTAssertTrue(app.buttons["game.resume"].waitForExistence(timeout: 3))
        app.buttons["game.resume"].tap()
        XCTAssertTrue(app.buttons["game.hint"].isEnabled)
        app.buttons["game.pause"].tap()
        app.buttons["game.leave"].tap()
        let confirmation = app.buttons.matching(identifier: "game.confirmLeave").firstMatch
        XCTAssertTrue(confirmation.waitForExistence(timeout: 4))
        confirmation.tap()
        XCTAssertTrue(app.buttons["menu.play"].waitForExistence(timeout: 4))
        app.buttons["menu.play"].tap()
        XCTAssertTrue(app.buttons["game.hint"].waitForExistence(timeout: 10))
    }
}
