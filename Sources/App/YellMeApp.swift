import SwiftUI
import FirebaseCore
import FirebaseAuth
import StoreKit

@main
struct YellMeApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}

// MARK: - AppState

@MainActor
class AppState: ObservableObject {
    @Published var authUser: FirebaseAuth.User?
    @Published var isFirebaseConfigured: Bool
    @Published var subscriptionTier: SubscriptionTier
    @Published var isBillingBusy = false
    @Published var billingMessage: String?

    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private var billingObserverTask: Task<Void, Never>?
    private let defaults = UserDefaults.standard
    private let subscriptionTierKey = "yellme.subscriptionTier"

    init() {
        let configured = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil
        isFirebaseConfigured = configured
        subscriptionTier = Self.loadTier(defaults: defaults, key: subscriptionTierKey)

        if configured {
            FirebaseApp.configure()
            authUser = Auth.auth().currentUser
            authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
                Task { @MainActor [weak self] in
                    self?.authUser = user
                }
            }
        }
    }

    var planFeatures: PlanFeatures {
        PlanCatalog.features(for: subscriptionTier)
    }

    private func setSubscriptionTier(_ tier: SubscriptionTier) {
        subscriptionTier = tier
        defaults.set(tier.rawValue, forKey: subscriptionTierKey)
    }

    #if DEBUG
    func debugOverrideSubscriptionTier(_ tier: SubscriptionTier) {
        setSubscriptionTier(tier)
    }
    #endif

    func refreshSubscriptionTier() async {
        let tier = await StoreKitService.shared.currentTier()
        if tier != subscriptionTier {
            setSubscriptionTier(tier)
        }
    }

    func startBillingMonitoring() {
        guard billingObserverTask == nil else { return }
        billingObserverTask = Task { [weak self] in
            for await _ in Transaction.updates {
                guard let self else { return }
                let tier = await StoreKitService.shared.currentTier()
                await MainActor.run {
                    self.setSubscriptionTier(tier)
                }
            }
        }
    }

    func purchasePremium() async {
        isBillingBusy = true
        billingMessage = nil
        defer { isBillingBusy = false }
        do {
            let tier = try await StoreKitService.shared.purchasePremium()
            setSubscriptionTier(tier)
            billingMessage = tier == .premium ? "Premiumを有効化しました。" : nil
        } catch {
            billingMessage = error.localizedDescription
        }
    }

    func restorePurchases() async {
        isBillingBusy = true
        billingMessage = nil
        defer { isBillingBusy = false }
        do {
            let tier = try await StoreKitService.shared.restorePurchases()
            setSubscriptionTier(tier)
            billingMessage = tier == .premium ? "購入情報を復元しました。" : "復元できるPremium購入が見つかりませんでした。"
        } catch {
            billingMessage = error.localizedDescription
        }
    }

    private static func loadTier(defaults: UserDefaults, key: String) -> SubscriptionTier {
        guard let raw = defaults.string(forKey: key),
              let tier = SubscriptionTier(rawValue: raw) else {
            return .free
        }
        return tier
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
        billingObserverTask?.cancel()
    }
}

// MARK: - RootView

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if !appState.isFirebaseConfigured {
                // Firebase未設定（開発/モック）モード
                ContentView()
                    .environmentObject(appState)
            } else if appState.authUser == nil {
                AuthView()
                    .transition(.opacity)
            } else if !hasCompletedOnboarding {
                OnboardingView()
                    .transition(.opacity)
            } else {
                ContentView()
                    .environmentObject(appState)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.authUser?.uid)
        .animation(.easeInOut(duration: 0.3), value: hasCompletedOnboarding)
        .task {
            await appState.refreshSubscriptionTier()
            appState.startBillingMonitoring()
        }
    }
}
