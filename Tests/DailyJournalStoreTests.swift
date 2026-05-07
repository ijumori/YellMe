import XCTest
@testable import YellMe

@MainActor
final class DailyJournalStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private var store: DailyJournalStore!
    private var suiteName: String = ""

    override func setUp() {
        super.setUp()
        suiteName = "DailyJournalStoreTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
        store = DailyJournalStore(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testRecordCompletionIncrementsSubmissionButXpOnlyOncePerDay() {
        let feedback1 = AIFeedback(mode: .praise, content: "good", createdAt: .now)
        store.recordCompletion(diaryText: "12345678901234567890", selectedWinIds: [], feedback: feedback1, baseXP: 1, bonusXP: 0)

        let feedback2 = AIFeedback(mode: .empathy, content: "again", createdAt: .now)
        store.recordCompletion(diaryText: "updated", selectedWinIds: ["w_walk"], feedback: feedback2, baseXP: 1, bonusXP: 1)

        let day = store.todayCalendarDay()
        let entry = store.entry(forCalendarDay: day)
        XCTAssertEqual(entry?.submissionCount, 2)
        XCTAssertEqual(store.companion.totalXP, 1)
    }

    func testRemainingSubmissionLimitUsesCurrentDayCount() {
        let feedback = AIFeedback(mode: .praise, content: "ok", createdAt: .now)
        store.recordCompletion(diaryText: "12345678901234567890", selectedWinIds: [], feedback: feedback, baseXP: 1, bonusXP: 0)
        XCTAssertEqual(store.remainingSubmissionsToday(limit: 3), 2)
        XCTAssertEqual(store.remainingSubmissionsToday(limit: 1), 0)
    }

    func testMergeRemoteEntriesPrefersNewerUpdatedAt() {
        let now = Date()
        let old = DailyEntry(id: "2099-01-01", diaryText: "old", selectedWinIds: [], aiFeedback: nil, submissionCount: 1, createdAt: now, updatedAt: now)
        let new = DailyEntry(id: "2099-01-01", diaryText: "new", selectedWinIds: ["w_walk"], aiFeedback: nil, submissionCount: 2, createdAt: now, updatedAt: now.addingTimeInterval(10))

        store.mergeRemoteEntries([old])
        store.mergeRemoteEntries([new])

        XCTAssertEqual(store.entry(forCalendarDay: "2099-01-01")?.diaryText, "new")
        XCTAssertEqual(store.entry(forCalendarDay: "2099-01-01")?.submissionCount, 2)
    }
}
