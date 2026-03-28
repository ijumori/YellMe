# エールミー 開発スキルマップ

## 必須スキル（開発参加に必要）

### Swift / SwiftUI
| スキル | 詳細 | 参考 |
|-------|------|------|
| Swift 5.9 基礎 | 型・クロージャ・async/await・actor | Swift Tour |
| SwiftUI | View・State・Binding・Environment | Apple Tutorials |
| MVVM | ObservableObject・@Published・@StateObject | |
| NavigationStack | 画面遷移・TabView | |
| ScrollView / LazyVStack | リスト表示・スクロール制御 | |
| async/await | 非同期処理・Task・MainActor | |

### Firebase
| スキル | 詳細 |
|-------|------|
| Firebase Auth | Apple Sign In・メール認証 |
| Firestore | ドキュメント・コレクション・クエリ・リアルタイム更新 |
| Firebase Storage | 画像アップロード・URL取得 |
| Firebase Cloud Messaging | プッシュ通知 |

### API連携
| スキル | 詳細 |
|-------|------|
| URLSession | HTTPリクエスト・async/await |
| JSON エンコード/デコード | Codable・JSONEncoder・JSONDecoder |
| Claude API | Anthropic Messages API仕様 |

### iOS開発環境
| スキル | 詳細 |
|-------|------|
| Xcode 16 | ビルド・デバッグ・Simulator |
| XcodeGen | `project.yml` 編集・`xcodegen generate` |
| Swift Package Manager | 依存パッケージ管理 |
| Git | ブランチ・PR・コンフリクト解消 |

---

## 推奨スキル（品質向上に役立つ）

| スキル | 詳細 |
|-------|------|
| XCTest | ユニットテスト・UIテスト |
| StoreKit 2 | アプリ内課金・サブスクリプション |
| UserNotifications | ローカル・プッシュ通知 |
| Instruments | パフォーマンス計測・メモリリーク検出 |
| TestFlight | ベータ配布・フィードバック収集 |
| App Store Connect | メタデータ・審査・リリース管理 |

---

## Claude Code スキル（このプロジェクト専用）

| コマンド | 用途 |
|---------|------|
| `/yellme-build` | プロジェクトをビルドして結果確認 |
| `/yellme-gen` | XcodeGenでプロジェクト再生成 |
| `/yellme-new-feature` | 新機能のファイル雛形を生成 |
| `/yellme-check` | コードの問題点を診断 |
| `/yellme-firebase` | Firebase関連のセットアップガイド |

→ 各スキルの定義: `.claude/commands/` を参照

---

## 学習ロードマップ（初心者向け）

```
Week 1: Swift基礎 → SwiftUI基礎 → MVVM理解
Week 2: async/await → URLSession → Claude API連携
Week 3: Firebase Auth → Firestore基本
Week 4: StoreKit 2 → App Store申請
```
