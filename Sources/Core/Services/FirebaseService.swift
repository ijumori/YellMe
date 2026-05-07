import Foundation
import FirebaseFirestore
import FirebaseAuth

actor FirebaseService {
    static let shared = FirebaseService()
    private let db = Firestore.firestore()

    // MARK: - 投稿

    func fetchPosts() async throws -> [Post] {
        let snapshot = try await db.collection("posts")
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .getDocuments()

        return try snapshot.documents.compactMap { doc in
            try doc.data(as: PostDTO.self).toPost()
        }
    }

    func savePost(_ post: Post) async throws {
        try ensureCurrentUserMatches(post.userId)
        let dto = PostDTO(from: post)
        try db.collection("posts").document(post.id).setData(from: dto)
    }

    // MARK: - リアクション

    func addReaction(_ reaction: Reaction, to postId: String) async throws {
        try ensureCurrentUserMatches(reaction.userId)
        let dto = ReactionDTO(from: reaction)
        try db.collection("posts")
            .document(postId)
            .collection("reactions")
            .document(reaction.id)
            .setData(from: dto)
    }

    // MARK: - ユーザー

    func fetchUser(id: String) async throws -> User? {
        let doc = try await db.collection("users").document(id).getDocument()
        return try doc.data(as: UserDTO.self).toUser()
    }

    func saveUser(_ user: User) async throws {
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

struct PostDTO: Codable {
    let id: String
    let userId: String
    let content: String
    let createdAt: Date
    let aiFeedbackMode: String?
    let aiFeedbackContent: String?
    let aiFeedbackCreatedAt: Date?

    init(from post: Post) {
        self.id = post.id
        self.userId = post.userId
        self.content = post.content
        self.createdAt = post.createdAt
        self.aiFeedbackMode = post.aiFeedback?.mode.rawValue
        self.aiFeedbackContent = post.aiFeedback?.content
        self.aiFeedbackCreatedAt = post.aiFeedback?.createdAt
    }

    func toPost() -> Post {
        var feedback: AIFeedback?
        if let modeRaw = aiFeedbackMode,
           let mode = FeedbackMode(rawValue: modeRaw),
           let content = aiFeedbackContent,
           let createdAt = aiFeedbackCreatedAt {
            feedback = AIFeedback(mode: mode, content: content, createdAt: createdAt)
        }
        return Post(id: id, userId: userId, content: content,
                    createdAt: createdAt, aiFeedback: feedback)
    }
}

struct ReactionDTO: Codable {
    let id: String
    let userId: String
    let type: String
    let createdAt: Date

    init(from reaction: Reaction) {
        self.id = reaction.id
        self.userId = reaction.userId
        self.type = reaction.type.rawValue
        self.createdAt = reaction.createdAt
    }
}

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
