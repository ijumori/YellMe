import Foundation

/// 日記エントリとコンパニオン進行のローカル永続化（UserDefaults）。
@MainActor
final class DailyJournalStore: ObservableObject {
    static let shared = DailyJournalStore()

    @Published private(set) var entries: [DailyEntry] = []
    @Published private(set) var companion: CompanionProgress = .initial

    private let defaults: UserDefaults
    private let entriesKey = "yellme.dailyJournal.entries"
    private let companionKey = "yellme.dailyJournal.companion"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func load() {
        if let data = defaults.data(forKey: entriesKey),
           let decoded = try? JSONDecoder().decode([DailyEntry].self, from: data) {
            entries = decoded.sorted { $0.id > $1.id }
        } else {
            entries = []
        }

        if let data = defaults.data(forKey: companionKey),
           let decoded = try? JSONDecoder().decode(CompanionProgress.self, from: data) {
            companion = decoded
        } else {
            companion = .initial
        }
    }

    func entry(forCalendarDay day: String) -> DailyEntry? {
        entries.first { $0.id == day }
    }

    func todayCalendarDay() -> String {
        Self.calendarDayString(for: Date())
    }

    func hasCompletedToday() -> Bool {
        let today = todayCalendarDay()
        guard let e = entry(forCalendarDay: today) else { return false }
        return e.submissionCount > 0 && e.aiFeedback != nil
    }

    func submissionCount(forCalendarDay day: String) -> Int {
        entry(forCalendarDay: day)?.submissionCount ?? 0
    }

    func remainingSubmissionsToday(limit: Int) -> Int {
        max(0, limit - submissionCount(forCalendarDay: todayCalendarDay()))
    }

    /// 記録完了時: エントリ保存・XP（初回完了時のみ）・ストリーク
    func recordCompletion(
        diaryText: String,
        selectedWinIds: [String],
        feedback: AIFeedback,
        baseXP: Int,
        bonusXP: Int
    ) {
        let day = todayCalendarDay()
        let now = Date()
        let sortedWins = Array(Set(selectedWinIds)).sorted()
        let existingEntry = entry(forCalendarDay: day)
        let hadFeedback = existingEntry?.aiFeedback != nil
        let previousCount = existingEntry?.submissionCount ?? 0

        let newEntry = DailyEntry(
            id: day,
            diaryText: diaryText,
            selectedWinIds: sortedWins,
            aiFeedback: feedback,
            submissionCount: previousCount + 1,
            createdAt: existingEntry?.createdAt ?? now,
            updatedAt: now
        )

        if let idx = entries.firstIndex(where: { $0.id == day }) {
            entries[idx] = newEntry
        } else {
            entries.insert(newEntry, at: 0)
        }
        entries.sort { $0.id > $1.id }

        if !hadFeedback {
            companion.totalXP += baseXP + bonusXP
            updateStreakForNewLog(newDay: day)
        }

        persist()
    }

    func consumeWelcomeBackFlag() {
        guard companion.showWelcomeBack else { return }
        companion.showWelcomeBack = false
        persist()
    }

    /// Firestore から取得したエントリをローカルへ安全に取り込む（新しい更新を優先）
    func mergeRemoteEntries(_ remoteEntries: [DailyEntry]) {
        guard !remoteEntries.isEmpty else { return }

        var mergedById = Dictionary(uniqueKeysWithValues: entries.map { ($0.id, $0) })
        for remote in remoteEntries {
            guard let local = mergedById[remote.id] else {
                mergedById[remote.id] = remote
                continue
            }
            if remote.updatedAt > local.updatedAt {
                mergedById[remote.id] = remote
            }
        }

        entries = mergedById.values.sorted { $0.id > $1.id }
        persist()
    }

    func clearAllForDebug() {
        entries = []
        companion = .initial
        defaults.removeObject(forKey: entriesKey)
        defaults.removeObject(forKey: companionKey)
    }

    // MARK: - Private

    private func persist() {
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: entriesKey)
        }
        if let data = try? JSONEncoder().encode(companion) {
            defaults.set(data, forKey: companionKey)
        }
    }

    private func updateStreakForNewLog(newDay: String) {
        guard let prev = companion.lastLogCalendarDay else {
            companion.streakDays = 1
            companion.lastLogCalendarDay = newDay
            companion.showWelcomeBack = false
            return
        }

        if prev == newDay {
            return
        }

        if isCalendarDayImmediatelyBefore(prev, newDay) {
            companion.streakDays += 1
            companion.showWelcomeBack = false
        } else if gapInCalendarDays(from: prev, to: newDay) >= 2 {
            companion.streakDays = 1
            companion.showWelcomeBack = true
        } else {
            companion.streakDays = 1
            companion.showWelcomeBack = false
        }

        companion.lastLogCalendarDay = newDay
    }

    /// prev の翌日が newDay なら true
    private func isCalendarDayImmediatelyBefore(_ prev: String, _ newDay: String) -> Bool {
        guard let dPrev = Self.date(fromCalendarDay: prev),
              let dNew = Self.date(fromCalendarDay: newDay) else { return false }
        let cal = Calendar.current
        guard let next = cal.date(byAdding: .day, value: 1, to: dPrev) else { return false }
        return cal.isDate(next, inSameDayAs: dNew)
    }

    private func gapInCalendarDays(from prev: String, to newDay: String) -> Int {
        guard let a = Self.date(fromCalendarDay: prev),
              let b = Self.date(fromCalendarDay: newDay) else { return 999 }
        let cal = Calendar.current
        return cal.dateComponents([.day], from: a, to: b).day ?? 999
    }

    static func calendarDayString(for date: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar.current
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    private static func date(fromCalendarDay day: String) -> Date? {
        let f = DateFormatter()
        f.calendar = Calendar.current
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: day)
    }
}
