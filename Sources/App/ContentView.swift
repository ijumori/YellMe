import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            TimelineView()
                .tabItem {
                    Label("タイムライン", systemImage: "heart.fill")
                }

            PostView()
                .tabItem {
                    Label("書く", systemImage: "pencil.and.scribble")
                }

            ProfileView()
                .tabItem {
                    Label("マイページ", systemImage: "person.fill")
                }
        }
        .tint(.pink)
    }
}

#Preview {
    ContentView()
}
