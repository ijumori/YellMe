# エールミー (YellMe) — Claude Code 開発ガイド

日記を書くとAI（Claude）が褒めフィードバックをくれるiOS SNSアプリ。批判ゼロ・共感100%の「やさしい世界」。

| 項目 | 内容 |
|------|------|
| Bundle ID | `com.takahiro.yellme` |
| 最低iOS | 17.0 |
| 言語 | Swift 5.9 / SwiftUI / MVVM |
| AI | Claude API（claude-sonnet-4-6） |

---

## クイックコマンド

```bash
xcodegen generate                          # 依存追加・設定変更後に必須
xcodebuild -project YellMe.xcodeproj -scheme YellMe \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
open YellMe.xcodeproj
```

### スラッシュコマンド
| コマンド | 用途 |
|---------|------|
| `/yellme-build` | ビルド実行・エラー確認 |
| `/yellme-gen` | XcodeGen再生成 |
| `/yellme-new-feature` | 新機能の雛形生成 |
| `/yellme-check` | プロジェクト全体診断 |
| `/yellme-firebase` | Firebase設定ガイド |
| `/yellme-review` | Swiftコードセルフレビュー |

---

## ディレクトリ構成

```
Sources/
├── App/          YellMeApp.swift（Firebase初期化） / ContentView.swift（TabView）
├── Core/
│   ├── Models/   Post.swift / User.swift / MockData.swift
│   └── Services/ ClaudeService.swift / FirebaseService.swift / Secrets.swift【gitignore】
└── Features/
    ├── Timeline/ TimelineView.swift / PostCardView.swift
    ├── Post/     PostView.swift
    └── Profile/  ProfileView.swift
```

---

## 開発ルール

### XcodeGen（最重要）
- `.xcodeproj` は**直接編集しない**
- 変更 → `project.yml` 編集 → `xcodegen generate`

### APIキー・機密情報（Hook強制）
- `Secrets.swift` / `GoogleService-Info.plist` はHookでWrite/Edit自動ブロック済み
- 手動で編集すること。絶対コミットしない
- `Secrets.claudeAPIKey == "YOUR_CLAUDE_API_KEY_HERE"` のとき自動モック動作

### View設計
- 1画面1ファイル: `Features/{Name}/{Name}View.swift`
- ViewModelは対応Viewファイル末尾に同居: `@MainActor class XxxViewModel: ObservableObject`

### Service設計
- `actor` で並行処理安全を確保
- FirestoreとのやりとりはDTO経由（モデルにFirestore依存を持ち込まない）

### モデル設計
- `Codable` + `Equatable` 必須（`Equatable`なしだと `.animation(value:)` エラー）

### 新機能追加手順
1. `/yellme-new-feature` で雛形生成
2. `Sources/Features/{Name}/` にView+ViewModel作成
3. 必要なら `ContentView.swift` にタブ追加
4. 変更あれば `xcodegen generate`

---

---

## エージェントルーティング

**チーフとして**: 指示を受けたら自分では実装せず、最適なエージェントを起動してタスクを委譲する。
複合タスクは複数エージェントを並列起動し、結果を統合して報告する。

| キーワード | エージェント | スキル |
|---|---|---|
| 設計・MVVM・XcodeGen・project.yml・actor | **Arch** | `/yellme-arch` |
| Firebase・Auth・Firestore・DTO・Rules | **Blaze** | `/yellme-firebase` |
| Claude API・プロンプト・FeedbackMode・AI | **Nova** | `/yellme-ai` |
| SwiftUI・View・UI・アニメ・デザイン | **Pixel** | `/yellme-ui` |
| レビュー・バグ・テスト・クラッシュ・品質 | **Shield** | `/yellme-review` |

### 複合タスク例
- 「Firebase Authを実装して」→ **Blaze**（実装）+ **Arch**（設計検証）並列起動
- 「投稿画面を作って」→ **Pixel**（View）+ **Arch**（ViewModel設計）並列起動
- 「AIフィードバックが遅い」→ **Nova**（プロンプト）+ **Shield**（コード診断）並列起動

---

## 詳細ドキュメント（参照用）

@.claude/docs/api-spec.md
@.claude/docs/firestore-schema.md
@.claude/docs/todo.md
