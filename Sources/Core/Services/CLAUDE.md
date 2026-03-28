# Services レイヤー規則

## actorパターン
- 全Serviceは `actor` として定義（Swift Concurrency安全）
- 外部から呼ぶときは `await service.method()`

## Secrets.swift
- このファイルはHookでWrite/Edit自動ブロック済み
- 手動編集のみ許可。APIキーは絶対コミットしない
- モック動作条件: `claudeAPIKey == "YOUR_CLAUDE_API_KEY_HERE"`

## FirebaseService
- FirestoreのCRUDは必ずDTO（`*DTO` struct）経由
- `Post` / `User` などのモデルにFirestore依存を持ち込まない
- DTOは `Codable` 準拠のみでよい

## ClaudeService
- FeedbackModeに応じてプロンプト切替
- タイムアウト: 30秒
- エラー時はモックフィードバックにフォールバック
