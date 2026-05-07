import Foundation

enum SubscriptionTier: String, Codable {
    case free
    case premium
}

struct PlanFeatures {
    let dailyJournalLimit: Int
    let canCustomizeAvatar: Bool
    let canDownloadMonthlyReport: Bool
}

enum PlanCatalog {
    static func features(for tier: SubscriptionTier) -> PlanFeatures {
        switch tier {
        case .free:
            return PlanFeatures(
                dailyJournalLimit: 1,
                canCustomizeAvatar: false,
                canDownloadMonthlyReport: false
            )
        case .premium:
            return PlanFeatures(
                dailyJournalLimit: 3,
                canCustomizeAvatar: true,
                canDownloadMonthlyReport: true
            )
        }
    }
}
