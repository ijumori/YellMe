# Firebase 実装パターン

## 基本方針
- FirestoreのデータとドメインモデルはDTO経由で完全分離
- `Post` / `User` などのモデルにFirestoreを直接import しない

## DTOパターン
```swift
// DTO（Firestore向け）
struct PostDTO: Codable {
    let id: String
    let userId: String
    let content: String
    let createdAt: Timestamp    // Firestore型
}

// ドメインモデル（UI向け）
struct Post: Codable, Equatable, Identifiable {
    let id: String
    let userId: String
    let content: String
    let createdAt: Date         // Swift標準型
}

// 変換
extension Post {
    init(from dto: PostDTO) {
        self.id = dto.id
        self.userId = dto.userId
        self.content = dto.content
        self.createdAt = dto.createdAt.dateValue()
    }
}
```

## FirebaseService パターン
```swift
actor FirebaseService {
    private let db = Firestore.firestore()

    func fetchPosts() async throws -> [Post] {
        let snapshot = try await db.collection("posts")
            .order(by: "createdAt", descending: true)
            .limit(to: 20)
            .getDocuments()
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: PostDTO.self)
        }.map { Post(from: $0) }
    }
}
```

## Firestoreコレクション
```
users/{userId}
posts/{postId}
posts/{postId}/reactions/{reactionId}
follows/{fromUid}_{toUid}
```

## Security Rules 原則
- 読み取り: 認証済みユーザーのみ（`request.auth != null`）
- 書き込み: 自分のドキュメントのみ（`request.auth.uid == userId`）
- 削除: オーナーのみ

## 注意事項
- `getDocuments()` は毎回フルフェッチ。本番ではページネーション必須
- `addSnapshotListener` はメモリリークに注意（`onDisappear` で解除）
- Firestore の課金は読み取り件数ベース。必要以上にフェッチしない
