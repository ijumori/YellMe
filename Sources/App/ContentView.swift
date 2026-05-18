import SwiftUI

enum AppTab: Int, Hashable {
    case home = 0
    case history = 1
    case profile = 2
}

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("いま", systemImage: "sun.max.fill")
                }
                .tag(AppTab.home)
                .accessibilityIdentifier("tab_home")

            HistoryView(onOpenProfile: { selectedTab = .profile })
                .tabItem {
                    Label("きろく", systemImage: "calendar")
                }
                .tag(AppTab.history)
                .accessibilityIdentifier("tab_history")

            ProfileView()
                .tabItem {
                    Label("マイページ", systemImage: "person.circle.fill")
                }
                .tag(AppTab.profile)
                .accessibilityIdentifier("tab_profile")
        }
        .tint(.pink)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
