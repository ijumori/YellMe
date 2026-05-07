import SwiftUI

struct TimelineView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = TimelineViewModel()

    private var useRemotePosts: Bool {
        appState.isFirebaseConfigured && appState.authUser != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.posts) { post in
                        PostCardView(post: post) { type in
                            Task {
                                await viewModel.addReaction(
                                    type: type,
                                    to: post.id,
                                    useRemote: useRemotePosts,
                                    userId: appState.authUser?.uid
                                )
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("エールミー")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.fetchPosts(useRemote: useRemotePosts)
            }
            .refreshable {
                await viewModel.fetchPosts(useRemote: useRemotePosts)
            }
        }
    }
}

@MainActor
class TimelineViewModel: ObservableObject {
    @Published var posts: [Post] = MockData.posts
    @Published var isLoading = false

    func fetchPosts(useRemote: Bool) async {
        isLoading = true
        defer { isLoading = false }

        if useRemote {
            do {
                posts = try await FirebaseService.shared.fetchPosts()
            } catch {
                posts = MockData.posts
            }
        } else {
            try? await Task.sleep(nanoseconds: 300_000_000)
            posts = MockData.posts
        }
    }

    func addReaction(type: ReactionType, to postId: String, useRemote: Bool, userId: String?) async {
        guard let index = posts.firstIndex(where: { $0.id == postId }) else { return }

        let localUserId = userId ?? "local-user"
        let reaction = Reaction(id: UUID().uuidString, userId: localUserId, type: type, createdAt: .now)

        posts[index].reactions.append(reaction)

        guard useRemote, let userId else { return }

        let remoteReaction = Reaction(id: reaction.id, userId: userId, type: type, createdAt: reaction.createdAt)

        do {
            try await FirebaseService.shared.addReaction(remoteReaction, to: postId)
        } catch {
            // リモート保存に失敗した場合は UI を元に戻して破綻を防ぐ
            if let rollbackIndex = posts.firstIndex(where: { $0.id == postId }),
               let reactionIndex = posts[rollbackIndex].reactions.firstIndex(where: { $0.id == remoteReaction.id }) {
                posts[rollbackIndex].reactions.remove(at: reactionIndex)
            }
        }
    }
}
