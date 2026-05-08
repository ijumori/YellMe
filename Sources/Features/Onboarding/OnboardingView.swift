import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            emoji: "📔",
            title: "日記を書こう",
            description: "今日あったこと、感じたこと、\nなんでも書いてOK。\n文章の上手さは関係ありません。"
        ),
        OnboardingPage(
            emoji: "💛",
            title: "AIが必ず褒めてくれる",
            description: "書いた内容から\nAIが必ず褒めポイントを見つけ出し、\n前向きなエールを贈ります。"
        ),
        OnboardingPage(
            emoji: "🌸",
            title: "自分とコンパニオンだけの記録",
            description: "誰かのタイムラインではなく、\nあなたの日記と「今日できたこと」で\n小さなコンパニオンがそっと成長します。\n批判ゼロ・共感100%の世界を、まずは自分の中から。"
        )
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.pink.opacity(0.1), Color.yellow.opacity(0.08)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                // ページコンテンツ
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // インジケーター + ボタン
                VStack(spacing: 24) {
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { i in
                            Circle()
                                .fill(i == currentPage ? Color.pink : Color.pink.opacity(0.25))
                                .frame(width: 8, height: 8)
                                .animation(.easeInOut, value: currentPage)
                        }
                    }

                    Button {
                        if currentPage < pages.count - 1 {
                            withAnimation { currentPage += 1 }
                        } else {
                            hasCompletedOnboarding = true
                        }
                    } label: {
                        Text(currentPage < pages.count - 1 ? "次へ" : "はじめる")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.pink)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 32)

                    Text("いつでも設定から見直せます")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 48)
            }
        }
    }

    private var topBar: some View {
        HStack {
            if currentPage > 0 {
                Button {
                    withAnimation { currentPage -= 1 }
                } label: {
                    Label("戻る", systemImage: "chevron.left")
                }
                .font(.subheadline)
            } else {
                Color.clear.frame(width: 60, height: 1)
            }

            Spacer()

            Button("スキップ") {
                hasCompletedOnboarding = true
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
}

private struct OnboardingPage: Identifiable {
    let id = UUID()
    let emoji: String
    let title: String
    let description: String
}

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text(page.emoji)
                .font(.system(size: 80))

            Text(page.title)
                .font(.system(size: 28, weight: .bold, design: .rounded))

            Text(page.description)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(6)

            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

#Preview {
    OnboardingView()
}
