import XCTest

final class YellMeUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()
    }

    func testTabBarNavigatesMainScreens() throws {
        XCTAssertTrue(app.staticTexts["いま"].waitForExistence(timeout: 8))

        app.tabBars.buttons["きろく"].tap()
        XCTAssertTrue(app.staticTexts["きろく"].waitForExistence(timeout: 5))

        app.tabBars.buttons["マイページ"].tap()
        XCTAssertTrue(app.staticTexts["マイページ"].waitForExistence(timeout: 5))

        app.tabBars.buttons["いま"].tap()
        XCTAssertTrue(app.staticTexts["いま"].waitForExistence(timeout: 5))
    }

    func testHistoryDetailAfterProfileShortcut() throws {
        try seedTodayEntryFromHome()

        app.tabBars.buttons["きろく"].tap()
        XCTAssertTrue(app.navigationBars["きろく"].waitForExistence(timeout: 8))

        XCTAssertFalse(app.staticTexts["まだ記録がありません"].waitForExistence(timeout: 2))

        let entryId = Self.todayCalendarDayId()
        let entryLink = historyEntryElement(id: entryId)
        XCTAssertTrue(entryLink.waitForExistence(timeout: 8))
        entryLink.tap()
        XCTAssertTrue(app.navigationBars["その日の記録"].waitForExistence(timeout: 8))

        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.navigationBars["きろく"].waitForExistence(timeout: 8))

        app.buttons["history_open_profile"].tap()
        XCTAssertTrue(app.navigationBars["マイページ"].waitForExistence(timeout: 8))

        app.tabBars.buttons["きろく"].tap()
        XCTAssertTrue(app.navigationBars["きろく"].waitForExistence(timeout: 8))

        let entryLinkAgain = historyEntryElement(id: entryId)
        XCTAssertTrue(entryLinkAgain.waitForExistence(timeout: 8))
        entryLinkAgain.tap()
        XCTAssertTrue(app.navigationBars["その日の記録"].waitForExistence(timeout: 8))
    }

    func testHomeDiaryAndSubmitFlow() throws {
        XCTAssertTrue(app.staticTexts["いま"].waitForExistence(timeout: 8))

        let diary = app.textViews["home_diary_editor"]
        if diary.waitForExistence(timeout: 5) {
            diary.tap()
            diary.typeText("今日はテストのために日記を書いています。がんばりました。")
        }

        let submit = app.buttons["home_submit_button"]
        XCTAssertTrue(submit.waitForExistence(timeout: 5))
        if submit.isEnabled {
            submit.tap()
            XCTAssertTrue(
                app.staticTexts["いま"].waitForExistence(timeout: 15)
                    || app.scrollViews.firstMatch.waitForExistence(timeout: 15)
            )
        }
    }

    private func seedTodayEntryFromHome() throws {
        XCTAssertTrue(app.navigationBars["いま"].waitForExistence(timeout: 8))

        let diary = app.textViews["home_diary_editor"]
        XCTAssertTrue(diary.waitForExistence(timeout: 5))
        diary.tap()
        diary.typeText("今日はテストのために日記を書いています。がんばりました。")

        let done = app.buttons["完了"]
        if done.waitForExistence(timeout: 2) {
            done.tap()
        }

        let submit = app.buttons["home_submit_button"]
        XCTAssertTrue(submit.waitForExistence(timeout: 5))
        XCTAssertTrue(submit.isEnabled)
        submit.tap()

        XCTAssertTrue(app.staticTexts["今日は記録済み"].waitForExistence(timeout: 30))
    }

    private func historyEntryElement(id: String) -> XCUIElement {
        let button = app.buttons["history_entry_\(id)"]
        if button.exists { return button }
        let cell = app.cells["history_entry_\(id)"]
        if cell.exists { return cell }
        return app.descendants(matching: .any)["history_entry_\(id)"]
    }

    private static func todayCalendarDayId() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
