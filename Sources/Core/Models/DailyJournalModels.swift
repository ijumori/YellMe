import Foundation

// MARK: - 今日できたこと（選択肢）

enum WinCategory: String, Codable, CaseIterable, Identifiable {
    case body
    case routine
    case mind
    case social

    var id: String { rawValue }

    var title: String {
        switch self {
        case .body: return "からだ"
        case .routine: return "くらし"
        case .mind: return "こころ"
        case .social: return "ひと"
        }
    }
}

struct WinOption: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let label: String
    let systemImage: String
    let category: WinCategory
}

enum WinCatalog {
    static let all: [WinOption] = [
        // からだ
        WinOption(id: "w_stretch", label: "ストレッチした", systemImage: "figure.flexibility", category: .body),
        WinOption(id: "w_walk", label: "散歩した", systemImage: "figure.walk", category: .body),
        WinOption(id: "w_water", label: "水をよく飲んだ", systemImage: "drop.fill", category: .body),
        WinOption(id: "w_sleep", label: "寝る準備ができた", systemImage: "bed.double.fill", category: .body),
        WinOption(id: "w_bath", label: "お風呂に入った", systemImage: "shower.fill", category: .body),
        WinOption(id: "w_meal", label: "ごはんを食べた", systemImage: "fork.knife", category: .body),
        // くらし
        WinOption(id: "w_clean", label: "片づけした", systemImage: "house.fill", category: .routine),
        WinOption(id: "w_laundry", label: "洗濯まわした", systemImage: "washer.fill", category: .routine),
        WinOption(id: "w_trash", label: "ゴミ出しした", systemImage: "trash.fill", category: .routine),
        WinOption(id: "w_cook", label: "料理した", systemImage: "flame.fill", category: .routine),
        WinOption(id: "w_shop", label: "買い物した", systemImage: "cart.fill", category: .routine),
        WinOption(id: "w_mail", label: "用事を一つ片づけた", systemImage: "envelope.fill", category: .routine),
        // こころ
        WinOption(id: "w_breathe", label: "深呼吸した", systemImage: "wind", category: .mind),
        WinOption(id: "w_journal", label: "気持ちを書いた", systemImage: "pencil.line", category: .mind),
        WinOption(id: "w_rest", label: "休むを選んだ", systemImage: "moon.zzz.fill", category: .mind),
        WinOption(id: "w_music", label: "音楽を聴いた", systemImage: "music.note", category: .mind),
        WinOption(id: "w_nature", label: "外の空気を吸った", systemImage: "leaf.fill", category: .mind),
        WinOption(id: "w_gratitude", label: "ありがとうを感じた", systemImage: "heart.fill", category: .mind),
        // ひと
        WinOption(id: "w_talk", label: "誰かと話した", systemImage: "bubble.left.and.bubble.right.fill", category: .social),
        WinOption(id: "w_message", label: "連絡を返した", systemImage: "message.fill", category: .social),
        WinOption(id: "w_smile", label: "笑顔になれた", systemImage: "face.smiling.fill", category: .social),
        WinOption(id: "w_help", label: "誰かを手伝った", systemImage: "hand.raised.fill", category: .social),
        WinOption(id: "w_listen", label: "人の話を聴いた", systemImage: "ear.fill", category: .social),
        WinOption(id: "w_boundary", label: "自分の線を守れた", systemImage: "shield.fill", category: .social),
    ]

    static func labels(for ids: [String]) -> [String] {
        ids.compactMap { id in all.first { $0.id == id }?.label }
    }

    static func options(for category: WinCategory) -> [WinOption] {
        all.filter { $0.category == category }
    }
}

// MARK: - 1日の記録

struct DailyEntry: Identifiable, Codable, Equatable, Hashable {
    /// ローカル暦の日付キー（例: 2026-05-01）
    let id: String
    var diaryText: String
    var selectedWinIds: [String]
    var aiFeedback: AIFeedback?
    /// その日の「記録してエールをもらう」実行回数
    var submissionCount: Int
    let createdAt: Date
    var updatedAt: Date

    var calendarDay: String { id }

    init(
        id: String,
        diaryText: String,
        selectedWinIds: [String],
        aiFeedback: AIFeedback?,
        submissionCount: Int = 0,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.diaryText = diaryText
        self.selectedWinIds = selectedWinIds
        self.aiFeedback = aiFeedback
        self.submissionCount = submissionCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case diaryText
        case selectedWinIds
        case aiFeedback
        case submissionCount
        case createdAt
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        diaryText = try c.decode(String.self, forKey: .diaryText)
        selectedWinIds = try c.decode([String].self, forKey: .selectedWinIds)
        aiFeedback = try c.decodeIfPresent(AIFeedback.self, forKey: .aiFeedback)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        updatedAt = try c.decode(Date.self, forKey: .updatedAt)

        if let count = try c.decodeIfPresent(Int.self, forKey: .submissionCount) {
            submissionCount = count
        } else {
            submissionCount = aiFeedback == nil ? 0 : 1
        }
    }
}

// MARK: - コンパニオン

enum CompanionPhase: String, Codable, CaseIterable, Equatable {
    case egg
    case hatchling
    case young
    case grown
    case majestic

    var title: String {
        switch self {
        case .egg: return "たまご"
        case .hatchling: return "ひな"
        case .young: return "そだち"
        case .grown: return "なかま"
        case .majestic: return "きらめき"
        }
    }

    var systemImage: String {
        switch self {
        case .egg: return "oval.fill"
        case .hatchling: return "bird.fill"
        case .young: return "hare.fill"
        case .grown: return "pawprint.fill"
        case .majestic: return "sparkles"
        }
    }

    /// この段階に入るのに必要な累計 XP（下限）
    static func minimumXP(for phase: CompanionPhase) -> Int {
        switch phase {
        case .egg: return 0
        case .hatchling: return 5
        case .young: return 15
        case .grown: return 30
        case .majestic: return 50
        }
    }

    static func phase(forTotalXP xp: Int) -> CompanionPhase {
        if xp >= Self.minimumXP(for: .majestic) { return .majestic }
        if xp >= Self.minimumXP(for: .grown) { return .grown }
        if xp >= Self.minimumXP(for: .young) { return .young }
        if xp >= Self.minimumXP(for: .hatchling) { return .hatchling }
        return .egg
    }

    /// 次の段階までの XP 幅（最終段階は伸びしろ表示用に 10）
    func xpSpanToNext() -> Int {
        switch self {
        case .egg: return CompanionPhase.minimumXP(for: .hatchling) - CompanionPhase.minimumXP(for: .egg)
        case .hatchling: return CompanionPhase.minimumXP(for: .young) - CompanionPhase.minimumXP(for: .hatchling)
        case .young: return CompanionPhase.minimumXP(for: .grown) - CompanionPhase.minimumXP(for: .young)
        case .grown: return CompanionPhase.minimumXP(for: .majestic) - CompanionPhase.minimumXP(for: .grown)
        case .majestic: return 10
        }
    }

    func progressInPhase(totalXP: Int) -> Double {
        let minXP = Self.minimumXP(for: self)
        let span = Double(max(xpSpanToNext(), 1))
        let pos = Double(totalXP - minXP)
        if self == .majestic {
            return min(1, pos / span)
        }
        return min(1, max(0, pos / span))
    }
}

struct CompanionProgress: Codable, Equatable {
    var totalXP: Int
    /// 最後に「今日の記録」を完了した暦日（id と同じ形式）
    var lastLogCalendarDay: String?
    var streakDays: Int
    /// 空き期間のあと最初の完了で一度だけ true（歓迎コピー用）
    var showWelcomeBack: Bool

    static let initial = CompanionProgress(totalXP: 0, lastLogCalendarDay: nil, streakDays: 0, showWelcomeBack: false)

    var phase: CompanionPhase {
        CompanionPhase.phase(forTotalXP: totalXP)
    }
}
