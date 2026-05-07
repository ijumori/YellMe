import Foundation
import StoreKit

actor StoreKitService {
    static let shared = StoreKitService()
    private let premiumMonthlyProductID: String

    init(bundle: Bundle = .main) {
        premiumMonthlyProductID = bundle.object(forInfoDictionaryKey: "YELLME_PREMIUM_PRODUCT_ID") as? String ?? ""
    }

    func fetchPremiumProduct() async throws -> Product {
        guard !premiumMonthlyProductID.isEmpty else {
            throw BillingError.missingProductConfiguration
        }
        let products = try await Product.products(for: [premiumMonthlyProductID])
        guard let product = products.first else {
            throw BillingError.productNotFound
        }
        return product
    }

    func currentTier() async -> SubscriptionTier {
        guard !premiumMonthlyProductID.isEmpty else { return .free }
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == premiumMonthlyProductID,
               transaction.revocationDate == nil,
               !transaction.isUpgraded,
               isNotExpired(transaction) {
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
        guard !premiumMonthlyProductID.isEmpty else {
            throw BillingError.missingProductConfiguration
        }
        try await AppStore.sync()
        return await currentTier()
    }

    private func isNotExpired(_ transaction: Transaction) -> Bool {
        guard let expiration = transaction.expirationDate else { return true }
        return expiration > Date()
    }
}

enum BillingError: LocalizedError {
    case missingProductConfiguration
    case productNotFound
    case unverifiedTransaction
    case userCancelled
    case pending
    case unknown

    var errorDescription: String? {
        switch self {
        case .missingProductConfiguration:
            return "課金商品の設定が未完了です。"
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
