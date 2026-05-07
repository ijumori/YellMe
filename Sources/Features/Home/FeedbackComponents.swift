import SwiftUI

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
