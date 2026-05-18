# Firebase 実装パターン

## 基本方針
- Firestore のデータとドメインモデルは **DTO 経由**で分離
- `DailyEntry` / `User` などに `FirebaseFirestore` を import しない

## DTO パターン（本リポジトリ）

```swift
// FirebaseService.swift 内
struct DailyEntryDTO: Codable {
    let id: String
    let diaryText: String
    let selectedWinIds: [String]
    // ...
}

struct UserDTO: Codable { /* ... */ }
```

ドメイン側は `DailyJournalModels.swift` の `DailyEntry` / `User` を UI で使用。

## FirebaseService パターン

```swift
actor FirebaseService {
    // users/{uid}/dailyEntries/{yyyy-MM-dd} へ save / fetch
    // DTO ↔ DailyEntry の変換は Service 内
}
```

## Firestore コレクション（現行）

```
users/{userId}
users/{userId}/dailyEntries/{yyyy-MM-dd}
```

**非対応（Rules で拒否）**: `posts/*`, `follows/*` — SNS 機能は採用しない。

## Security Rules

- 定義: `firebase/firestore.rules`, `firebase/storage.rules`
- 詳細: [.claude/docs/firestore-schema.md](../.claude/docs/firestore-schema.md)

## 注意事項
- 読み取り件数に注意（不要な全件フェッチを避ける）
- リスナーは画面ライフサイクルに合わせて解除
- オフライン時は `DailyJournalStore` のローカル保存を優先し、同期失敗は非致命扱い
