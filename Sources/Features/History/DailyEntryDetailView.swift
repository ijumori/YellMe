import SwiftUI

struct DailyEntryDetailView: View {
    let entry: DailyEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(entryTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(Text("記録日 \(entryTitle)"))

                if !entry.diaryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("日記")
                            .font(.headline)
                        Text(entry.diaryText)
                            .font(.body)
                            .lineSpacing(4)
                    }
                }

                if !entry.selectedWinIds.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("今日できたこと")
                            .font(.headline)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], spacing: 8) {
                            ForEach(WinCatalog.labels(for: entry.selectedWinIds), id: \.self) { label in
                                Text(label)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .frame(minHeight: 44)
                                    .background(Color.secondary.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                }

                if let fb = entry.aiFeedback {
                    AIFeedbackResultView(feedback: fb)
                }
            }
            .padding()
        }
        .navigationTitle("その日の記録")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var entryTitle: String {
        guard let d = parseDay(entry.id) else { return entry.id }
        return d.formatted(date: .long, time: .omitted)
    }

    private func parseDay(_ day: String) -> Date? {
        let f = DateFormatter()
        f.calendar = Calendar.current
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: day)
    }
}

#Preview {
    NavigationStack {
        DailyEntryDetailView(
            entry: DailyEntry(
                id: DailyJournalStore.calendarDayString(for: .now),
                diaryText: "のんびり過ごした",
                selectedWinIds: ["w_walk", "w_water"],
                aiFeedback: AIFeedback(mode: .praise, content: "よかったね。", createdAt: .now),
                createdAt: .now,
                updatedAt: .now
            )
        )
    }
}
