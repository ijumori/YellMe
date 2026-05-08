import Foundation
import FirebaseFirestore
import FirebaseAuth

actor FirebaseService {
    static let shared = FirebaseService()
    private let db = Firestore.firestore()

    // MARK: - ユーザー

    func fetchUser(id: String) async throws -> User? {
        try ensureCurrentUserMatches(id)
        let doc = try await db.collection("users").document(id).getDocument()
        return try doc.data(as: UserDTO.self).toUser()
    }

    func saveUser(_ user: User) async throws {
        try ensureCurrentUserMatches(user.id)
        let dto = UserDTO(from: user)
        try db.collection("users").document(user.id).setData(from: dto)
    }

    // MARK: - 日次記録

    func saveDailyEntry(_ entry: DailyEntry, userId: String) async throws {
        try ensureCurrentUserMatches(userId)
        let dto = DailyEntryDTO(from: entry)
        try db.collection("users")
            .document(userId)
            .collection("dailyEntries")
            .document(entry.id)
            .setData(from: dto)
    }

    func fetchDailyEntry(userId: String, calendarDay: String) async throws -> DailyEntry? {
        try ensureCurrentUserMatches(userId)
        let doc = try await db.collection("users")
            .document(userId)
            .collection("dailyEntries")
            .document(calendarDay)
            .getDocument()
        guard doc.exists else { return nil }
        return try doc.data(as: DailyEntryDTO.self).toDailyEntry()
    }

    func fetchRecentDailyEntries(userId: String, limit: Int = 14) async throws -> [DailyEntry] {
        try ensureCurrentUserMatches(userId)
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("dailyEntries")
            .order(by: "updatedAt", descending: true)
            .limit(to: limit)
            .getDocuments()
        return try snapshot.documents.compactMap { doc in
            try doc.data(as: DailyEntryDTO.self).toDailyEntry()
        }
    }

    // MARK: - Security

    private func ensureCurrentUserMatches(_ userId: String) throws {
        guard let currentUid = Auth.auth().currentUser?.uid else {
            throw FirebaseServiceError.notAuthenticated
        }
        guard currentUid == userId else {
            throw FirebaseServiceError.userMismatch
        }
    }
}

enum FirebaseServiceError: LocalizedError {
    case notAuthenticated
    case userMismatch

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "ログイン状態が確認できません。"
        case .userMismatch:
            return "ユーザー情報が一致しないため保存できません。"
        }
    }
}

// MARK: - DTOs（Firestore用の変換層）

struct UserDTO: Codable {
    let id: String
    let displayName: String
    let bio: String
    let profileImageURL: String?
    let createdAt: Date

    init(from user: User) {
        self.id = user.id
        self.displayName = user.displayName
        self.bio = user.bio
        self.profileImageURL = user.profileImageURL
        self.createdAt = user.createdAt
    }

    func toUser() -> User {
        User(id: id, displayName: displayName, bio: bio,
             profileImageURL: profileImageURL, createdAt: createdAt)
    }
}

struct DailyEntryDTO: Codable {
    let id: String
    let diaryText: String
    let selectedWinIds: [String]
    let aiFeedbackMode: String?
    let aiFeedbackContent: String?
    let aiFeedbackCreatedAt: Date?
    let submissionCount: Int?
    let createdAt: Date
    let updatedAt: Date

    init(from entry: DailyEntry) {
        self.id = entry.id
        self.diaryText = entry.diaryText
        self.selectedWinIds = entry.selectedWinIds
        self.aiFeedbackMode = entry.aiFeedback?.mode.rawValue
        self.aiFeedbackContent = entry.aiFeedback?.content
        self.aiFeedbackCreatedAt = entry.aiFeedback?.createdAt
        self.submissionCount = entry.submissionCount
        self.createdAt = entry.createdAt
        self.updatedAt = entry.updatedAt
    }

    func toDailyEntry() -> DailyEntry {
        var feedback: AIFeedback?
        if let modeRaw = aiFeedbackMode,
           let mode = FeedbackMode(rawValue: modeRaw),
           let content = aiFeedbackContent,
           let createdAt = aiFeedbackCreatedAt {
            feedback = AIFeedback(mode: mode, content: content, createdAt: createdAt)
        }
        return DailyEntry(
            id: id,
            diaryText: diaryText,
            selectedWinIds: selectedWinIds,
            aiFeedback: feedback,
            submissionCount: submissionCount ?? (feedback == nil ? 0 : 1),
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
