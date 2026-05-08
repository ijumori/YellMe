import Foundation

struct User: Identifiable, Codable, Equatable {
    let id: String
    var displayName: String
    var bio: String
    var profileImageURL: String?
    let createdAt: Date

    init(id: String = UUID().uuidString,
         displayName: String,
         bio: String = "",
         profileImageURL: String? = nil,
         createdAt: Date = .now) {
        self.id = id
        self.displayName = displayName
        self.bio = bio
        self.profileImageURL = profileImageURL
        self.createdAt = createdAt
    }
}
