import SwiftUI

struct PostCardView: View {
    let post: Post
    let onReaction: (ReactionType) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 投稿内容
            Text(post.content)
                .font(.body)
                .foregroundStyle(.primary)

            // AIフィードバック
            if let feedback = post.aiFeedback {
                AIFeedbackBubble(feedback: feedback)
            }

            // リアクション
            HStack(spacing: 12) {
                ForEach(ReactionType.allCases, id: \.self) { type in
                    ReactionButton(type: type, count: post.reactions.filter { $0.type == type }.count) {
                        onReaction(type)
                    }
                }
                Spacer()
                Text(post.createdAt.formatted(.relative(presentation: .named)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct AIFeedbackBubble: View {
    let feedback: AIFeedback

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: feedback.mode.icon)
                .foregroundStyle(.pink)
                .font(.caption)
                .padding(6)
                .background(Color.pink.opacity(0.1))
                .clipShape(Circle())

            Text(feedback.content)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .background(Color.pink.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ReactionButton: View {
    let type: ReactionType
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(type.emoji)
                    .font(.caption)
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.secondary.opacity(0.1))
            .clipShape(Capsule())
        }
    }
}
