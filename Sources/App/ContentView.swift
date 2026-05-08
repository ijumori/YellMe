import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("いま", systemImage: "sun.max.fill")
                }

            HistoryView()
                .tabItem {
                    Label("きろく", systemImage: "calendar")
                }
        }
        .tint(.pink)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
