# Services レイヤー規則

## actorパターン
- 全Serviceは `actor` として定義（Swift Concurrency安全）
- 外部から呼ぶときは `await service.method()`

## Secrets.swift / Keychain
- `Secrets.swift` はHookでWrite/Edit自動ブロック済み（手動編集のみ）
- 実行時のキー解決: `ClaudeAPIKeyStore.resolvedKey()`（Keychain 優先 → `Secrets.claudeAPIKey`）
- モック条件: `ClaudeAPIKeyPolicy.shouldUseMockAPI(for: ClaudeAPIKeyStore.resolvedKey())`

## FirebaseService
- FirestoreのCRUDは必ずDTO（`*DTO` struct）経由
- `Post` / `User` などのモデルにFirestore依存を持ち込まない
- DTOは `Codable` 準拠のみでよい

## ClaudeService
- FeedbackModeに応じてプロンプト切替
- タイムアウト: 30秒
- エラー時はモックフィードバックにフォールバック
