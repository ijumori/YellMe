# エールミー (YellMe)

> 書くたびに、少し自分が好きになれる。

日記を書くと、AIが必ず褒めポイントを見つけてフィードバックしてくれる個人記録アプリ。
批判ゼロ・共感100%の「やさしい世界」を提供する。

---

## 機能

- **日記投稿** — テキストで今日の出来事を書く（書き出しヒント付き）
- **今日できたこと** — からだ・くらし・こころ・ひとの4カテゴリ、24項目から選択
- **AIエール（4モード）** — 褒めて / 共感して / アドバイスして / 勇気をくれ
- **コンパニオン育成** — XPが貯まり、たまご→ひな→そだち→なかま→きらめきの5段階で成長
- **ストリーク** — 連続記録日を追跡、休み明けに「おかえり」メッセージ
- **きろく** — 月別に過去の日記とAIエールを振り返り
- **マイページ** — プロフィール編集・プラン管理・法的リンク
- **Premium（月額サブスク）** — エール1日3回、コンパニオン着せ替え、月次レポートDL

---

## 技術スタック

| 項目 | 内容 |
|------|------|
| プラットフォーム | iOS 17.0+ (iPhone専用) |
| 言語 | Swift 5.9 |
| UI | SwiftUI |
| アーキテクチャ | MVVM |
| AI | Claude API（claude-sonnet-4-6） |
| バックエンド | Firebase（Auth / Firestore） |
| 認証 | Sign in with Apple |
| 課金 | StoreKit 2 |
| プロジェクト生成 | XcodeGen |
| CI | GitHub Actions |
| ASCアップロード | fastlane deliver |

---

## セットアップ

### 必要なもの

- Xcode 16.0+
- iOS 17.0+ Simulator または実機
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

### 手順

```bash
# 1. リポジトリをクローン
git clone <repo-url>
cd YellMe

# 2. Secrets.swift を用意
./scripts/bootstrap-secrets.sh

# 3. Xcode プロジェクトを生成
xcodegen generate

# 4. APIキーを設定（未設定ならモック動作）
# Secrets.swift を開いて claudeAPIKey を設定

# 5. Firebase を設定（任意）
# GoogleService-Info.plist を Resources/ に配置

# 6. 開く
open YellMe.xcodeproj
```

### Keychain（推奨）

実行時は Keychain に保存したキーを優先し、なければ `Secrets.swift` を参照。DEBUGビルドの「マイページ」下部から Keychain にコピー可能。

---

## プロジェクト構成

```
YellMe/
├── project.yml              # XcodeGen 設定（single source of truth）
├── .swiftlint.yml           # SwiftLint
├── firebase.json            # Firebase CLI
├── firebase/                # Firestore / Storage Rules
├── fastlane/                # deliver メタデータ・Fastfile
├── AppStoreMetadata/        # スクショ・プレビュー・ASC用テキスト
├── scripts/                 # Archive・アップロード・スクショ生成
├── guidelines/              # アーキテクチャ・UI・Firebase・コーディング規約
├── Sources/
│   ├── App/                 # YellMeApp, ContentView
│   ├── Core/Models/         # DailyJournal, Feedback, User
│   ├── Core/Services/       # Claude, Firebase, Auth, DailyJournalStore, StoreKit
│   └── Features/
│       ├── Home/            # いま（日記・エール）
│       ├── History/         # きろく
│       ├── Profile/         # マイページ
│       ├── Auth/            # Apple サインイン
│       └── Onboarding/
├── Tests/                   # Unit（YellMeTests）
├── UITests/                 # UI（YellMeUITests）
└── Resources/               # GoogleService-Info.plist（gitignore）
```

---

## App Store

- **バージョン**: 1.0.1 (build 8)
- **ステータス**: 審査提出済み
- **Bundle ID**: `com.takahiro.yellme`
- **SKU**: `yellme-ios-001`
- **プライバシーポリシー**: https://ijumori.github.io/YellMe/privacy.html
- **利用規約**: https://ijumori.github.io/YellMe/terms.html
- **サポート**: https://ijumori.github.io/YellMe/support.html

### リリース手順

1. `project.yml` のバージョン/ビルド番号を更新 → `xcodegen generate`
2. `./scripts/archive-export-appstore.sh` で IPA 作成
3. Transporter または fastlane でアップロード
4. `bundle exec fastlane upload_all` でメタデータ反映

詳細: [.claude/docs/app-store-release.md](.claude/docs/app-store-release.md)

---

## 開発ガイド

### テスト

```bash
swiftlint lint                              # 静的解析
xcodebuild test -project YellMe.xcodeproj -scheme YellMe \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'
```

詳細: [.claude/docs/ios-test-guide.md](.claude/docs/ios-test-guide.md)

### CI（GitHub Actions）

`.github/workflows/ios.yml` が `xcodegen generate` → シミュレータビルドを実行。

---

## ライセンス

Private
