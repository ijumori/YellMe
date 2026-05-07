# Firestore スキーマ設計

## コレクション構造

```
users/{userId}           → User情報
users/{userId}/dailyEntries/{yyyy-MM-dd} → 1日記録（日記/できたこと/AIエール/回数）
posts/{postId}           → 投稿・AIフィードバック
posts/{postId}/reactions → リアクション
follows/{docId}          → フォロー関係（Security Rules 用に `fromUserId` / `toUserId` フィールド必須）
```

## データモデル

```swift
Post     { id, userId, content, createdAt, aiFeedback?, reactions[] }
AIFeedback { mode: FeedbackMode, content: String, createdAt: Date }  // Equatable必須
FeedbackMode: praise | empathy | advice | courage
Reaction { id, userId, type: ReactionType, createdAt }
ReactionType: heart | understood | goodJob
User     { id, displayName, avatarURL?, bio?, createdAt }
DailyEntry { id, diaryText, selectedWinIds[], aiFeedback?, submissionCount, createdAt, updatedAt }
```

## DTO規則
- FirestoreとのやりとりはDTO経由（モデルにFirestore依存を持ち込まない）
- `Codable` + `Equatable` 必須準拠（`.animation(value:)` エラー防止）

---

## Security Rules（リポジトリ内の定義）

本リポジトリのルールファイル:

- `firebase/firestore.rules`
- `firebase/storage.rules`
- ルートの `firebase.json`（CLI が参照）

### フォロー保存時のフィールド（Rules 整合）

`follows` コレクションの各ドキュメントには、少なくとも次を含めること（`firebase/firestore.rules` と一致）:

| フィールド | 型 | 説明 |
|------------|-----|------|
| `fromUserId` | string | フォローする側の UID（`request.auth.uid` と一致） |
| `toUserId` | string | フォローされる側の UID |

### 日次記録の制約（Rules 整合）

- パス: `users/{userId}/dailyEntries/{calendarDay}`
- `id == calendarDay` を強制
- `submissionCount` は `int` かつ `0以上`
- update 時は `createdAt` を変更不可
- update 時は `submissionCount` を減らせない
- delete は禁止（現在仕様）

### デプロイ・検証チェックリスト

1. [Firebase CLI](https://firebase.google.com/docs/cli) をインストールし、`firebase login`
2. プロジェクトを紐付け: `firebase use <project-id>`
3. Firestore Rules をデプロイ: `firebase deploy --only firestore:rules`
4. Storage Rules をデプロイ: `firebase deploy --only storage`
5. （推奨）エミュレータで検証: `firebase emulators:start --only firestore` のうえ、クライアントをエミュレータ向けに接続して読み書きテスト
6. コンソールの **Rules プレイグラウンド** で、未ログイン・他人 UID による `create` / `update` が拒否されることを確認
7. 本番公開前に「テストモード」のまま放置していないかコンソールで確認
