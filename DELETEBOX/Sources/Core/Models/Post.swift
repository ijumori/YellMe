import Foundation

struct Post: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    let content: String
    let createdAt: Date
    var aiFeedback: AIFeedback?
    var reactions: [Reaction]

    init(id: String = UUID().uuidString,
         userId: String,
         content: String,
         createdAt: Date = .now,
         aiFeedback: AIFeedback? = nil,
         reactions: [Reaction] = []) {
        self.id = id
        self.userId = userId
        self.content = content
        self.createdAt = createdAt
        self.aiFeedback = aiFeedback
        self.reactions = reactions
    }
}

struct AIFeedback: Codable, Equatable, Hashable {
    let mode: FeedbackMode
    let content: String
    let createdAt: Date
}

enum FeedbackMode: String, Codable, CaseIterable {
    case praise = "praise"       // 褒めモード
    case empathy = "empathy"     // 共感モード
    case advice = "advice"       // アドバイスモード
    case courage = "courage"     // 勇気モード

    var label: String {
        switch self {
        case .praise:  return "褒めて"
        case .empathy: return "共感して"
        case .advice:  return "アドバイスして"
        case .courage: return "勇気をくれ"
        }
    }

    var icon: String {
        switch self {
        case .praise:  return "star.fill"
        case .empathy: return "heart.fill"
        case .advice:  return "lightbulb.fill"
        case .courage: return "bolt.fill"
        }
    }
}

struct Reaction: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    let type: ReactionType
    let createdAt: Date
}

enum ReactionType: String, Codable, CaseIterable {
    case heart = "heart"           // ♡
    case understood = "understood" // わかる
    case goodJob = "goodJob"       // がんばったね

    var emoji: String {
        switch self {
        case .heart:      return "❤️"
        case .understood: return "わかる"
        case .goodJob:    return "がんばったね"
        }
    }
}
