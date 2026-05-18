import Foundation
import StoreKit

actor StoreKitService {
    static let shared = StoreKitService()
    private let premiumMonthlyProductID: String

    init(bundle: Bundle = .main) {
        premiumMonthlyProductID = bundle.object(forInfoDictionaryKey: "YELLME_PREMIUM_PRODUCT_ID") as? String ?? ""
    }

    /// App Store から商品メタデータを取得（審査環境ではネットワークや ASC 設定で空配列になり得るためリトライする）。
    func fetchPremiumProduct() async throws -> Product {
        guard !premiumMonthlyProductID.isEmpty else {
            throw BillingError.missingProductConfiguration
        }
        var lastError: Error = BillingError.productNotFound
        for attempt in 0..<4 {
            if attempt > 0 {
                let ns = 400_000_000 + UInt64(attempt) * 200_000_000
                try await Task.sleep(nanoseconds: ns)
            }
            do {
                let products = try await Product.products(for: [premiumMonthlyProductID])
                if let product = products.first { return product }
                lastError = BillingError.productNotFound
            } catch {
                lastError = error
            }
        }
        throw lastError
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
        guard AppStore.canMakePayments else {
            throw BillingError.paymentsDisabled
        }
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
    case paymentsDisabled
    case unverifiedTransaction
    case userCancelled
    case pending
    case unknown

    var errorDescription: String? {
        switch self {
        case .missingProductConfiguration:
            return "課金商品の設定が未完了です。"
        case .productNotFound:
            return "App Store からプランを取得できませんでした。通信を確認のうえ、しばらくしてから再度お試しください。"
        case .paymentsDisabled:
            return "この端末では App 内課金が無効になっています（ペアレンタルコントロール等）。設定をご確認ください。"
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
