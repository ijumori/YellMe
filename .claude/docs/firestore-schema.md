# Firestore スキーマ設計

## コレクション構造

```
users/{userId}           → User情報
posts/{postId}           → 投稿・AIフィードバック
posts/{postId}/reactions → リアクション
follows/{uid_uid}        → フォロー関係（{fromUid}_{toUid}）
```

## データモデル

```swift
Post     { id, userId, content, createdAt, aiFeedback?, reactions[] }
AIFeedback { mode: FeedbackMode, content: String, createdAt: Date }  // Equatable必須
FeedbackMode: praise | empathy | advice | courage
Reaction { id, userId, type: ReactionType, createdAt }
ReactionType: heart | understood | goodJob
User     { id, displayName, avatarURL?, bio?, createdAt }
```

## DTO規則
- FirestoreとのやりとりはDTO経由（モデルにFirestore依存を持ち込まない）
- `Codable` + `Equatable` 必須準拠（`.animation(value:)` エラー防止）
