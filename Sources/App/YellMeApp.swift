import SwiftUI
import FirebaseCore
import FirebaseAuth

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

    private var authStateHandle: AuthStateDidChangeListenerHandle?

    init() {
        let configured = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil
        isFirebaseConfigured = configured

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

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
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
            } else if appState.authUser == nil {
                AuthView()
                    .transition(.opacity)
            } else if !hasCompletedOnboarding {
                OnboardingView()
                    .transition(.opacity)
            } else {
                ContentView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.authUser?.uid)
        .animation(.easeInOut(duration: 0.3), value: hasCompletedOnboarding)
    }
}
