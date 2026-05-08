import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @AppStorage("yellme.lastNotifiedCompanionPhase") private var lastNotifiedCompanionPhaseRaw = CompanionPhase.egg.rawValue
    @ObservedObject private var store = DailyJournalStore.shared
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedCategory: WinCategory = .body
    @State private var showWelcomeBanner = false
    @State private var showEvolutionAlert = false
    @State private var evolvedPhase: CompanionPhase?
    private var dailyLimit: Int { appState.planFeatures.dailyJournalLimit }
    private var remainingToday: Int { store.remainingSubmissionsToday(limit: dailyLimit) }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        headerSection

                        companionCard

                        if showWelcomeBanner {
                            welcomeBackBanner
                        }

                        if store.hasCompletedToday() {
                            completedTodaySection
                        }

                        if remainingToday > 0 {
                            diarySection
                            winsSection
                            modeSection
                            submitSection(proxy: proxy)
                        } else {
                            limitReachedSection
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("いま")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.syncFromStore(store)
                Task {
                    await viewModel.hydrateFromFirestoreIfNeeded(store: store, appState: appState)
                }
                checkEvolutionIfNeeded(currentPhase: store.companion.phase)
                if store.companion.showWelcomeBack {
                    showWelcomeBanner = true
                    store.consumeWelcomeBackFlag()
                }
            }
            .onChange(of: store.entries) { _, _ in
                viewModel.syncFromStore(store)
            }
            .onChange(of: store.companion.phase) { _, newValue in
                checkEvolutionIfNeeded(currentPhase: newValue)
            }
            .alert("コンパニオンが進化しました", isPresented: $showEvolutionAlert) {
                Button("うれしい") {}
            } message: {
                if let phase = evolvedPhase {
                    Text("\(phase.title) に進化しました。\n\(phase.celebrationMessage)")
                }
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        HStack {
            Text(Date.now.formatted(date: .abbreviated, time: .omitted))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .accessibilityLabel(Text("今日の日付 \(Date.now.formatted(date: .long, time: .omitted))"))
            Spacer()
            if store.hasCompletedToday() {
                Label("今日は記録済み", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
                    .accessibilityHint(Text("今日の記録は完了しています"))
            }
        }
    }

    private var usageSection: some View {
        HStack {
            Text("今日の記録: \(store.submissionCount(forCalendarDay: store.todayCalendarDay())) / \(dailyLimit)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(appState.subscriptionTier == .premium ? "Premium" : "Free")
                .font(.caption2)
                .fontWeight(.semibold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.pink.opacity(0.15))
                .clipShape(Capsule())
        }
    }

    private var companionCard: some View {
        let phase = store.companion.phase
        let resting = companionIsResting
        let progress = phase.progressInPhase(totalXP: store.companion.totalXP)

        return VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.pink.opacity(0.12))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.pink.opacity(0.25), lineWidth: 1)
                    }

                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .stroke(Color.secondary.opacity(0.18), lineWidth: 5)
                            .frame(width: 120, height: 120)
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(Color.pink, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 120, height: 120)
                            .opacity(resting ? 0.35 : 1)

                        Image(systemName: phase.systemImage)
                            .font(.system(size: 48))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.pink)
                            .opacity(resting ? 0.45 : 1)
                            .accessibilityHidden(true)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(Text(companionVoiceOverLabel(phase: phase, resting: resting, progress: progress)))

                    Text(phase.title)
                        .font(.headline)
                    Text("累計 \(store.companion.totalXP) XP ・ 続いている日 \(store.companion.streakDays)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel(Text("累計エックスピー \(store.companion.totalXP)、続いている日 \(store.companion.streakDays)"))

                    if resting {
                        Text("おやすみ中")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .accessibilityLabel(Text("コンパニオンはおやすみ中。成長は一休みしています"))
                    }
                }
                .padding(20)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var welcomeBackBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "sparkles")
                .foregroundStyle(.pink)
                .accessibilityHidden(true)
            Text("また会えてうれしいよ。今日もやさしく記録していこう。")
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
        .padding()
        .background(Color.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
    }

    private var completedTodaySection: some View {
        Group {
            if let entry = store.entry(forCalendarDay: store.todayCalendarDay()),
               let fb = entry.aiFeedback {
                VStack(alignment: .leading, spacing: 12) {
                    Text("今日の記録")
                        .font(.headline)
                    usageSection
                    if !entry.diaryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(entry.diaryText)
                            .font(.body)
                            .lineSpacing(4)
                    }
                    if !entry.selectedWinIds.isEmpty {
                        FlowWinsRow(ids: entry.selectedWinIds)
                    }
                    AIFeedbackResultView(feedback: fb)
                }
            }
        }
    }

    private var limitReachedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("今日の更新上限に達しました")
                .font(.headline)
            usageSection
            Text(appState.subscriptionTier == .premium
                 ? "明日また記録できます。"
                 : "Premiumで1日3回まで更新できます。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var diarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("今日はどんな日でしたか？")
                .font(.headline)
            Text("20文字以上の日記、または「今日できたこと」をひとつ選ぶと記録できます。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            TextEditor(text: $viewModel.diaryText)
                .frame(minHeight: 140)
                .padding(12)
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .accessibilityLabel(Text("今日の日記"))

            if viewModel.diaryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                starterPrompts
            }
        }
    }

    private var starterPrompts: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("書き出しのヒント")
                .font(.caption)
                .foregroundStyle(.secondary)
            WrapHStack(items: HomeViewModel.diaryStarterPrompts) { prompt in
                Button(prompt) {
                    viewModel.diaryText = prompt + "\n"
                }
                .font(.caption)
                .buttonStyle(.bordered)
            }
        }
        .padding(.top, 4)
    }

    private var winsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日できたこと")
                .font(.headline)
            Picker("カテゴリ", selection: $selectedCategory) {
                ForEach(WinCategory.allCases) { cat in
                    Text(cat.title).tag(cat)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel(Text("今日できたことのカテゴリ"))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(WinCatalog.options(for: selectedCategory)) { option in
                    winChip(option: option)
                }
            }
        }
    }

    private func winChip(option: WinOption) -> some View {
        let selected = viewModel.selectedWinIds.contains(option.id)
        return Button {
            viewModel.toggleWin(option.id)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: option.systemImage)
                    .font(.title3)
                    .frame(width: 28, height: 28)
                    .accessibilityHidden(true)
                Text(option.label)
                    .font(.subheadline)
                    .fontWeight(selected ? .semibold : .regular)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.85)
                    .lineLimit(2)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(selected ? Color.pink.opacity(0.22) : Color.secondary.opacity(0.08))
            .foregroundStyle(selected ? Color.pink : Color.primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selected ? Color.pink.opacity(0.5) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(option.label))
        .accessibilityValue(Text(selected ? "選択中" : "未選択"))
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("どんなエールが欲しいですか？")
                .font(.headline)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(FeedbackMode.allCases, id: \.self) { mode in
                    FeedbackModeButton(mode: mode, isSelected: viewModel.selectedMode == mode) {
                        viewModel.selectedMode = mode
                    }
                }
            }
        }
    }

    private func submitSection(proxy: ScrollViewProxy) -> some View {
        VStack(spacing: 12) {
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

            if let notice = viewModel.syncNoticeMessage {
                HStack {
                    Image(systemName: "icloud.slash")
                        .foregroundStyle(.secondary)
                    Text(notice)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Button {
                Task {
                    await viewModel.submit(store: store, appState: appState, dailyLimit: dailyLimit)
                    if viewModel.feedback != nil {
                        withAnimation {
                            proxy.scrollTo("homeFeedback", anchor: .top)
                        }
                    }
                }
            } label: {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "heart.text.square.fill")
                        Text("記録してエールをもらう")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.canSubmit(remainingLimit: remainingToday) ? Color.pink : Color.gray.opacity(0.45))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!viewModel.canSubmit(remainingLimit: remainingToday) || viewModel.isLoading)
            .accessibilityHint(Text(viewModel.canSubmit(remainingLimit: remainingToday) ? "日記と今日できたことを保存し、エールを表示します" : "日記を20文字以上書くか、今日の残り回数を確認してください"))

            if !viewModel.canSubmit(remainingLimit: remainingToday) {
                Text(remainingToday == 0
                     ? "今日はここまで。続きは明日、またはPremiumで回数アップ。"
                     : "無理しなくて大丈夫。少しだけ書くか、できたことをひとつ選んでみてね。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let feedback = viewModel.feedback {
                AIFeedbackResultView(feedback: feedback)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .id("homeFeedback")
            }
        }
        .animation(.spring(), value: viewModel.feedback)
    }

    private var companionIsResting: Bool {
        if store.hasCompletedToday() { return false }
        guard let last = store.companion.lastLogCalendarDay else { return false }
        let today = store.todayCalendarDay()
        if last == today { return false }
        if isDayImmediatelyBefore(last, today) { return false }
        return true
    }

    private func isDayImmediatelyBefore(_ last: String, _ today: String) -> Bool {
        guard let dLast = parseCalendarDay(last),
              let dToday = parseCalendarDay(today) else { return false }
        let cal = Calendar.current
        guard let next = cal.date(byAdding: .day, value: 1, to: dLast) else { return false }
        return cal.isDate(next, inSameDayAs: dToday)
    }

    private func parseCalendarDay(_ day: String) -> Date? {
        let f = DateFormatter()
        f.calendar = Calendar.current
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: day)
    }

    private func companionVoiceOverLabel(phase: CompanionPhase, resting: Bool, progress: Double) -> String {
        let pct = Int((progress * 100).rounded())
        if resting {
            return "コンパニオン、\(phase.title)。おやすみ中で成長は一休み。段階の進み \(pct)パーセント"
        }
        return "コンパニオン、\(phase.title)。段階の進み \(pct)パーセント"
    }

    private func checkEvolutionIfNeeded(currentPhase: CompanionPhase) {
        let last = CompanionPhase(rawValue: lastNotifiedCompanionPhaseRaw) ?? .egg
        guard currentPhase.rank > last.rank else { return }
        evolvedPhase = currentPhase
        showEvolutionAlert = true
        lastNotifiedCompanionPhaseRaw = currentPhase.rawValue
    }
}

// MARK: - Flow wins (read-only chips for completed entry)

private struct FlowWinsRow: View {
    let ids: [String]

    var body: some View {
        let labels = WinCatalog.labels(for: ids)
        if labels.isEmpty { EmptyView() }
        else {
            VStack(alignment: .leading, spacing: 6) {
                Text("えらんだこと")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                WrapHStack(items: labels) { label in
                    Text(label)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
        }
    }
}

/// 簡易ラップ（SwiftUI の FlowLayout がない環境向け）
private struct WrapHStack<Item: Hashable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(rows().enumerated()), id: \.offset) { _, row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { item in
                        content(item)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private func rows() -> [[Item]] {
        stride(from: 0, to: items.count, by: 2).map { i in
            Array(items[i..<min(i + 2, items.count)])
        }
    }
}

// MARK: - HomeViewModel

@MainActor
final class HomeViewModel: ObservableObject {
    private static let minDiaryChars = 20
    private static let baseXP = 1
    private static let bonusXP = 1
    static let diaryStarterPrompts: [String] = [
        "今日いちばんホッとしたことは、",
        "少しでも前に進めたことは、",
        "今の気持ちを一言で言うと、",
    ]

    @Published var diaryText = ""
    @Published var selectedWinIds: Set<String> = []
    @Published var selectedMode: FeedbackMode = .praise
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var syncNoticeMessage: String?
    @Published var feedback: AIFeedback?
    private var didHydrateFromFirestore = false

    func canSubmit(remainingLimit: Int) -> Bool {
        remainingLimit > 0 && Self.meetsCompletionRule(diary: diaryText, wins: selectedWinIds)
    }

    static func meetsCompletionRule(diary: String, wins: Set<String>) -> Bool {
        let trimmed = diary.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= minDiaryChars || !wins.isEmpty
    }

    func syncFromStore(_ store: DailyJournalStore) {
        let day = store.todayCalendarDay()
        guard let entry = store.entry(forCalendarDay: day) else {
            feedback = nil
            return
        }
        diaryText = entry.diaryText
        selectedWinIds = Set(entry.selectedWinIds)
        feedback = entry.aiFeedback
    }

    func toggleWin(_ id: String) {
        if selectedWinIds.contains(id) {
            selectedWinIds.remove(id)
        } else {
            selectedWinIds.insert(id)
        }
    }

    func submit(store: DailyJournalStore, appState: AppState, dailyLimit: Int) async {
        guard canSubmit(remainingLimit: store.remainingSubmissionsToday(limit: dailyLimit)) else { return }
        isLoading = true
        errorMessage = nil
        syncNoticeMessage = nil
        defer { isLoading = false }

        let diaryTrimmed = diaryText.trimmingCharacters(in: .whitespacesAndNewlines)
        let winArray = Array(selectedWinIds).sorted()
        let userMessage = Self.buildUserMessage(diary: diaryText, winIds: winArray)

        do {
            let apiKey = ClaudeAPIKeyStore.resolvedKey()
            let useMock = ClaudeAPIKeyPolicy.shouldUseMockAPI(for: apiKey)
            let feedbackText: String

            if useMock {
                try? await Task.sleep(nanoseconds: 800_000_000)
                feedbackText = MockData.mockFeedback(mode: selectedMode, userMessage: userMessage)
            } else {
                let claudeService = ClaudeService(apiKey: apiKey)
                feedbackText = try await claudeService.generateFeedback(userMessage: userMessage, mode: selectedMode)
            }

            let fb = AIFeedback(mode: selectedMode, content: feedbackText, createdAt: .now)
            feedback = fb

            let both = diaryTrimmed.count >= Self.minDiaryChars && !winArray.isEmpty
            let bonus = both ? Self.bonusXP : 0
            store.recordCompletion(
                diaryText: diaryText,
                selectedWinIds: winArray,
                feedback: fb,
                baseXP: Self.baseXP,
                bonusXP: bonus
            )
            await syncTodayEntryToFirestoreIfPossible(store: store, appState: appState)
        } catch {
            errorMessage = "エールの取得に失敗しました。\n\(error.localizedDescription)"
        }
    }

    func hydrateFromFirestoreIfNeeded(store: DailyJournalStore, appState: AppState) async {
        guard !didHydrateFromFirestore else { return }
        didHydrateFromFirestore = true

        guard appState.isFirebaseConfigured, let userId = appState.authUser?.uid else { return }
        do {
            let remoteToday = try await FirebaseService.shared.fetchDailyEntry(
                userId: userId,
                calendarDay: store.todayCalendarDay()
            )
            let remoteRecent = try await FirebaseService.shared.fetchRecentDailyEntries(userId: userId, limit: 14)

            var merged = remoteRecent
            if let remoteToday {
                merged.removeAll { $0.id == remoteToday.id }
                merged.append(remoteToday)
            }
            store.mergeRemoteEntries(merged)
            syncFromStore(store)
        } catch {
            syncNoticeMessage = "クラウド同期が一時的に利用できません。ローカル保存で続行します。"
        }
    }

    private func syncTodayEntryToFirestoreIfPossible(store: DailyJournalStore, appState: AppState) async {
        guard appState.isFirebaseConfigured, let userId = appState.authUser?.uid else { return }
        guard let todayEntry = store.entry(forCalendarDay: store.todayCalendarDay()) else { return }

        Task {
            do {
                try await FirebaseService.shared.saveDailyEntry(todayEntry, userId: userId)
            } catch {
                await MainActor.run {
                    self.syncNoticeMessage = "クラウドへの反映に失敗しました。端末には保存されています。"
                }
            }
        }
    }

    private static func buildUserMessage(diary: String, winIds: [String]) -> String {
        let labels = WinCatalog.labels(for: winIds)
        let diaryBlock = diary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "（未入力）"
            : diary
        let winsBlock: String
        if labels.isEmpty {
            winsBlock = "（なし）"
        } else {
            winsBlock = labels.map { "- \($0)" }.joined(separator: "\n")
        }
        return """
        【日記】
        \(diaryBlock)

        【今日できたこと（アプリで選んだ項目）】
        \(winsBlock)
        """
    }
}

#Preview {
    HomeView()
}
