import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var store = DailyJournalStore.shared

    private var grouped: [(month: String, entries: [DailyEntry])] {
        let withFeedback = store.entries.filter { $0.aiFeedback != nil }
        let dict = Dictionary(grouping: withFeedback) { entry -> String in
            monthKey(for: entry.id)
        }
        return dict.keys.sorted(by: >).map { key in
            (month: key, entries: (dict[key] ?? []).sorted { $0.id > $1.id })
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if grouped.isEmpty {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "calendar")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                            Text("まだ記録がありません")
                                .font(.headline)
                            Text("「いま」タブで今日の記録をすると、ここに並びます。")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    }
                }
                ForEach(grouped, id: \.month) { group in
                    Section(header: Text(sectionTitle(for: group.month))) {
                        ForEach(group.entries) { entry in
                            NavigationLink(value: entry) {
                                HistoryRowView(entry: entry)
                            }
                        }
                    }
                }

                Section {
                    Button {
                        // 月次ダウンロード実処理は次段で追加
                    } label: {
                        Label(
                            appState.planFeatures.canDownloadMonthlyReport
                                ? "月次レポートをダウンロード"
                                : "月次ダウンロードはPremiumで利用可能",
                            systemImage: appState.planFeatures.canDownloadMonthlyReport ? "arrow.down.circle" : "lock.fill"
                        )
                    }
                    .disabled(!appState.planFeatures.canDownloadMonthlyReport)

                    NavigationLink {
                        ProfileView()
                    } label: {
                        Label("マイページ・設定", systemImage: "person.circle")
                    }
                    .accessibilityLabel(Text("マイページと設定"))
                }
            }
            .navigationTitle("きろく")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: DailyEntry.self) { entry in
                DailyEntryDetailView(entry: entry)
            }
        }
    }

    private func monthKey(for calendarDay: String) -> String {
        String(calendarDay.prefix(7))
    }

    private func sectionTitle(for yyyyMM: String) -> String {
        guard yyyyMM.count == 7,
              let y = Int(yyyyMM.prefix(4)),
              let m = Int(yyyyMM.suffix(2)) else { return yyyyMM }
        var comps = DateComponents()
        comps.year = y
        comps.month = m
        comps.day = 1
        guard let date = Calendar.current.date(from: comps) else { return yyyyMM }
        return date.formatted(.dateTime.year().month(.wide))
    }
}

private struct HistoryRowView: View {
    let entry: DailyEntry

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text(dayLabel)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(diarySnippet)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                winIcons
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(dayLabel)、\(diarySnippet)"))
    }

    private var dayLabel: String {
        guard let d = parseDay(entry.id) else { return entry.id }
        return d.formatted(date: .abbreviated, time: .omitted)
    }

    private var diarySnippet: String {
        let t = entry.diaryText.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return "できたこと中心の記録" }
        return t
    }

    @ViewBuilder
    private var winIcons: some View {
        let ids = Array(entry.selectedWinIds.prefix(3))
        if ids.isEmpty { EmptyView() }
        else {
            HStack(spacing: 6) {
                ForEach(ids, id: \.self) { id in
                    if let opt = WinCatalog.all.first(where: { $0.id == id }) {
                        Image(systemName: opt.systemImage)
                            .font(.caption)
                            .foregroundStyle(.pink)
                            .accessibilityLabel(Text(opt.label))
                    }
                }
            }
        }
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
    HistoryView()
}
