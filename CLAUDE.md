# エールミー (YellMe) — Claude Code 開発ガイド

日記と「今日できたこと」で記録し、コンパニオンが成長する。AI（Claude）が褒めフィードバックをくれる iOS アプリ。批判ゼロ・共感100%の「やさしい世界」。

| 項目 | 内容 |
|------|------|
| Bundle ID | `com.takahiro.yellme` |
| 最低iOS | 17.0 |
| 言語 | Swift 5.9 / SwiftUI / MVVM |
| AI | Claude API（claude-sonnet-4-6） |
| 現バージョン | 1.0.1（build 8） |

---

## クイックコマンド

```bash
xcodegen generate                          # 依存追加・設定変更後に必須
xcodebuild -project YellMe.xcodeproj -scheme YellMe \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
open YellMe.xcodeproj

# App Store 提出用: Archive → IPA
./scripts/archive-export-appstore.sh
# API キーでアップロードまで
# export ASC_API_KEY_ID=... ASC_API_ISSUER_ID=... ASC_API_KEY_PATH=.../AuthKey_xxx.p8
# ./scripts/archive-export-appstore.sh --upload

# メタデータ・スクショ・プレビューを ASC に一括反映（Apple ID 認証）
# export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
# bundle exec fastlane upload_all
```

### fastlane（ASCアップロード）
- `fastlane/Fastfile` にレーン定義（`upload_all` / `asc_screenshots` / `bump_build` / `upload_build` / `submit_review`）
- `fastlane/metadata/ja/` — 概要・プロモ・キーワード等（正本）
- `AppStoreMetadata/ja/` — ASC API 用テキスト（`fastlane/metadata/ja/` と同期すること）
- メタデータ運用: `.claude/docs/metadata-sources.md`
- `bundle exec fastlane upload_all` で一括アップロード（Apple ID 認証）

### スラッシュコマンド
| コマンド | 用途 |
|---------|------|
| `/yellme-build` | ビルド実行・エラー確認 |
| `/yellme-gen` | XcodeGen再生成 |
| `/yellme-new-feature` | 新機能の雛形生成 |
| `/yellme-check` | プロジェクト全体診断 |
| `/yellme-arch` | 設計・アーキテクチャ |
| `/yellme-firebase` | Firebase設定ガイド |
| `/yellme-ai` | Claude API・プロンプト |
| `/yellme-ui` | SwiftUI・UI/UX |
| `/yellme-review` | コードレビュー |

---

## ディレクトリ構成

```
Sources/
├── App/          YellMeApp.swift / ContentView.swift / InteractivePopGestureEnabler.swift / UITestingSupport.swift
├── Core/
│   ├── Models/   DailyJournalModels.swift / FeedbackModels.swift / User.swift / MockData.swift
│   └── Services/ ClaudeService.swift / FirebaseService.swift / AuthService.swift / DailyJournalStore.swift / StoreKitService.swift / Secrets.swift【gitignore】
└── Features/
    ├── Home/       HomeView.swift（いまタブ）
    ├── History/    HistoryView.swift / DailyEntryDetailView.swift（きろくタブ）
    ├── Profile/    ProfileView.swift（マイページ）
    ├── Auth/       AuthView.swift
    └── Onboarding/ OnboardingView.swift
Tests/              YellMeTests（Unit: DailyJournalStoreTests）
UITests/            YellMeUITests（タブ遷移・記録フロー）
scripts/            Archive・ASCアップロード・スクショ生成等
fastlane/           deliver メタデータ・Fastfile
guidelines/         アーキテクチャ・UI・Firebase・コーディング規約
.swiftlint.yml      SwiftLint 設定
```

---

## 開発ルール

### XcodeGen（最重要）
- `.xcodeproj` は**直接編集しない**
- 変更 → `project.yml` 編集 → `xcodegen generate`

### APIキー・機密情報（Hook強制）
- `Secrets.swift` / `GoogleService-Info.plist` はHookでWrite/Edit自動ブロック済み
- 手動で編集すること。絶対コミットしない
- `ClaudeAPIKeyPolicy.shouldUseMockAPI(for: ClaudeAPIKeyStore.resolvedKey())` が true のとき自動モック動作（Keychain 優先）

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

## エージェントルーティング

**チーフとして**: 指示を受けたら最適なエージェントを起動してタスクを委譲する。
複合タスクは複数エージェントを並列起動し、結果を統合して報告する。

| キーワード | エージェント | コマンド |
|---|---|---|
| 設計・MVVM・XcodeGen・project.yml・actor | **Arch** | `/yellme-arch` |
| Firebase・Auth・Firestore・DTO・Rules | **Blaze** | `/yellme-firebase` |
| Claude API・プロンプト・FeedbackMode・AI | **Nova** | `/yellme-ai` |
| SwiftUI・View・UI・アニメ・デザイン | **Pixel** | `/yellme-ui` |
| レビュー・バグ・テスト・クラッシュ・品質 | **Shield** | `/yellme-review` |

---

## 詳細ドキュメント（参照用）

@.claude/docs/api-spec.md
@.claude/docs/firestore-schema.md
@.claude/docs/todo.md
@.claude/docs/ios-test-guide.md
