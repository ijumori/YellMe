import SwiftUI
import FirebaseAuth

struct PostView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = PostViewModel()
    @State private var selectedMode: FeedbackMode = .praise
    @Namespace private var feedbackAnchor

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 24) {
                        // テキスト入力
                        VStack(alignment: .leading, spacing: 8) {
                            Text("今日はどんな日でしたか？")
                                .font(.headline)
                            TextEditor(text: $viewModel.content)
                                .frame(minHeight: 160)
                                .padding(12)
                                .background(Color.secondary.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // フィードバックモード選択
                        VStack(alignment: .leading, spacing: 12) {
                            Text("どんなエールが欲しいですか？")
                                .font(.headline)
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(FeedbackMode.allCases, id: \.self) { mode in
                                    FeedbackModeButton(mode: mode, isSelected: selectedMode == mode) {
                                        selectedMode = mode
                                    }
                                }
                            }
                        }

                        // 投稿ボタン
                        Button {
                            Task {
                                await viewModel.submit(
                                    mode: selectedMode,
                                    userId: appState.authUser?.uid,
                                    canUseFirebase: appState.isFirebaseConfigured
                                )
                                if viewModel.feedback != nil {
                                    withAnimation {
                                        proxy.scrollTo("feedbackResult", anchor: .top)
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "paperplane.fill")
                                    Text("エールをもらう")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.content.isEmpty ? Color.gray : Color.pink)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(viewModel.content.isEmpty || viewModel.isLoading)

                        // エラー表示
                        if let error = viewModel.errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundStyle(.red)
                                Text(error)
                                    .font(.subheadline)
                                    .foregroundStyle(.red)
                            }
                            .padding()
                            .background(Color.red.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        // AIフィードバック表示
                        if let feedback = viewModel.feedback {
                            AIFeedbackResultView(feedback: feedback)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                                .id("feedbackResult")
                        }
                    }
                    .padding()
                    .animation(.spring(), value: viewModel.feedback)
                }
            }
            .navigationTitle("書く")
        }
    }
}

struct FeedbackModeButton: View {
    let mode: FeedbackMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: mode.icon)
                Text(mode.label)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.vertical, 12)
            .background(isSelected ? Color.pink : Color.secondary.opacity(0.1))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .accessibilityLabel(Text(mode.label))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

struct AIFeedbackResultView: View {
    let feedback: AIFeedback

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: feedback.mode.icon)
                    .foregroundStyle(.pink)
                Text("エールが届きました")
                    .font(.headline)
                Spacer()
            }
            Text(feedback.content)
                .font(.body)
                .lineSpacing(4)
        }
        .padding()
        .background(
            LinearGradient(colors: [Color.pink.opacity(0.08), Color.orange.opacity(0.05)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.pink.opacity(0.2), lineWidth: 1)
        )
    }
}

@MainActor
class PostViewModel: ObservableObject {
    @Published var content: String = ""
    @Published var isLoading: Bool = false
    @Published var feedback: AIFeedback?
    @Published var errorMessage: String?

    func submit(mode: FeedbackMode, userId: String?, canUseFirebase: Bool) async {
        guard !content.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let apiKey = ClaudeAPIKeyStore.resolvedKey()
            let useMock = ClaudeAPIKeyPolicy.shouldUseMockAPI(for: apiKey)
            let feedbackText: String

            if useMock {
                // APIキー未設定時はモックを使用
                try? await Task.sleep(nanoseconds: 800_000_000)
                feedbackText = MockData.mockFeedback(mode: mode, content: content)
            } else {
                let claudeService = ClaudeService(apiKey: apiKey)
                feedbackText = try await claudeService.generateFeedback(userMessage: content, mode: mode)
            }

            let generatedFeedback = AIFeedback(mode: mode, content: feedbackText, createdAt: .now)
            feedback = generatedFeedback

            if canUseFirebase, let userId {
                let post = Post(userId: userId, content: content, aiFeedback: generatedFeedback)
                do {
                    try await FirebaseService.shared.savePost(post)
                } catch {
                    // エール生成は成功しているため、保存失敗は非致命扱いにする
                    errorMessage = "エールは届きましたが、投稿の保存に失敗しました。"
                }
            }
        } catch {
            errorMessage = "エールの取得に失敗しました。\n\(error.localizedDescription)"
        }
    }
}
