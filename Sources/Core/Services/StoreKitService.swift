import Foundation
import StoreKit

actor StoreKitService {
    static let shared = StoreKitService()

    // TODO: App Store Connect の実プロダクトIDに合わせる
    private let premiumMonthlyProductID = "com.takahiro.yellme.premium.monthly"

    func fetchPremiumProduct() async throws -> Product {
        let products = try await Product.products(for: [premiumMonthlyProductID])
        guard let product = products.first else {
            throw BillingError.productNotFound
        }
        return product
    }

    func currentTier() async -> SubscriptionTier {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == premiumMonthlyProductID,
               transaction.revocationDate == nil,
               !transaction.isUpgraded {
                return .premium
            }
        }
        return .free
    }

    func purchasePremium() async throws -> SubscriptionTier {
        let product = try await fetchPremiumProduct()
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                await transaction.finish()
                return await currentTier()
            case .unverified:
                throw BillingError.unverifiedTransaction
            }
        case .userCancelled:
            throw BillingError.userCancelled
        case .pending:
            throw BillingError.pending
        @unknown default:
            throw BillingError.unknown
        }
    }

    func restorePurchases() async throws -> SubscriptionTier {
        try await AppStore.sync()
        return await currentTier()
    }
}

enum BillingError: LocalizedError {
    case productNotFound
    case unverifiedTransaction
    case userCancelled
    case pending
    case unknown

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "購入商品が見つかりません。"
        case .unverifiedTransaction:
            return "購入の検証に失敗しました。"
        case .userCancelled:
            return "購入がキャンセルされました。"
        case .pending:
            return "購入が保留中です。"
        case .unknown:
            return "課金処理で不明なエラーが発生しました。"
        }
    }
}
