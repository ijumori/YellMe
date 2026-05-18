import Foundation

enum UITestingSupport {
    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains("-ui-testing")
    }

    static func prepareIfNeeded() {
        guard isEnabled else { return }

        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "hasCompletedOnboarding")
        defaults.removeObject(forKey: "yellme.subscriptionTier")
        defaults.removeObject(forKey: "yellme.lastNotifiedCompanionPhase")
        defaults.removeObject(forKey: "yellme.dailyJournal.entries")
        defaults.removeObject(forKey: "yellme.dailyJournal.companion")
    }
}
