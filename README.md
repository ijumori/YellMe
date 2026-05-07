# エールミー (YellMe)

> 書くたびに、少し自分が好きになれる。

日記を書くと、AIが必ず褒めポイントを見つけてフィードバックしてくれるやさしいSNSアプリ。
批判ゼロ・共感100%の「やさしい世界」を提供する。

---

## スクリーンショット

| タイムライン | 書く | エール受け取り |
|------------|------|-------------|
| （準備中） | （準備中） | （準備中） |

---

## 機能

- **日記投稿** — テキストで今日の出来事を書く
- **AIエール（4モード）** — 褒めて / 共感して / アドバイスして / 勇気をくれ
- **タイムライン** — フォローしたユーザーの投稿が流れる
- **やさしいリアクション** — ❤️ / わかる / がんばったね（批判不可）
- **マイページ** — 自分の投稿一覧・プロフィール

---

## 技術スタック

| 項目 | 内容 |
|------|------|
| プラットフォーム | iOS 17.0+ |
| 言語 | Swift 5.9 |
| UI | SwiftUI |
| アーキテクチャ | MVVM |
| AI | Claude API（claude-sonnet-4-6） |
| バックエンド | Firebase（Auth / Firestore / Storage） |
| 課金 | StoreKit 2 |
| プロジェクト生成 | XcodeGen |

---

## セットアップ

### 必要なもの

- Xcode 16.0+
- iOS 17.0+ Simulator または実機
- [Homebrew](https://brew.sh)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

### 手順

```bash
# 1. リポジトリをクローン
git clone <repo-url>
cd YellMe

# 2. XcodeGen をインストール（未インストールの場合）
brew install xcodegen

# 3. ローカル用 Secrets.swift を用意（未作成のときだけコピー）
./scripts/bootstrap-secrets.sh

# 4. Xcode プロジェクトを生成
xcodegen generate

# 5. APIキーを設定
# Secrets.swift を開いて claudeAPIKey を設定（未設定ならモック動作）

# 6. Firebase を設定（任意）
# GoogleService-Info.plist を Resources/ に配置

# 7. Xcode で開く
open YellMe.xcodeproj
```

### APIキーの設定

`./scripts/bootstrap-secrets.sh` で `Secrets.swift` を用意したうえで、キーを設定：

```swift
enum Secrets {
    static let claudeAPIKey = "sk-ant-xxxxxxxxxxxxxxxx"
}
```

> ⚠️ `Secrets.swift` は `.gitignore` に含まれています。絶対にコミットしないこと。

APIキー未設定の場合はモックデータでフィードバックが返ります。

### Keychain（推奨・開発時）

実行時は **Keychain に保存したキーを優先**し、なければ `Secrets.swift` を参照します。実機やシミュレータでは、DEBUG ビルドの「マイページ」下部から `Secrets` のキーを Keychain にコピーできます。コピー後は `Secrets.swift` をプレースホルダーに戻すと、リポジトリにキーを残さずに開発しやすくなります。

> **注意**: 脱獄端末などでは Keychain も完全には守れません。配布ビルドではプロキシ経由や独自バックエンドでのキー管理を検討してください。

### Firebase Security Rules

- Firestore / Storage のルールは `firebase/firestore.rules` と `firebase/storage.rules`（`firebase.json` から参照）
- デプロイ手順・検証チェックリストは [.claude/docs/firestore-schema.md](.claude/docs/firestore-schema.md) の「Security Rules」節を参照

### CI（GitHub Actions）

`.github/workflows/ios.yml` が `xcodegen generate` のうえシミュレータ向けビルドを実行します。

1. リポジトリシークレット（任意）: `YELLME_CLAUDE_API_KEY` — 設定すると `scripts/write-secrets-from-env.sh` が `Secrets.swift` を生成（未設定ならプレースホルダのままコンパイルのみ）
2. ローカルと同様、ワークフロー内で `./scripts/bootstrap-secrets.sh` を先に実行

---

## プロジェクト構成

```
YellMe/
├── project.yml                    # XcodeGen 設定
├── firebase.json                  # Firebase CLI（rules 参照）
├── firebase/
│   ├── firestore.rules
│   └── storage.rules
├── .github/workflows/ios.yml      # CI ビルド
├── Sources/
│   ├── App/
│   │   ├── YellMeApp.swift        # アプリエントリーポイント
│   │   └── ContentView.swift      # タブナビゲーション
│   ├── Core/
│   │   ├── Models/
│   │   │   ├── Post.swift         # 投稿・AIフィードバック・リアクション モデル
│   │   │   ├── User.swift         # ユーザーモデル
│   │   │   └── MockData.swift     # 開発用モックデータ
│   │   └── Services/
│   │       ├── ClaudeService.swift    # Claude API クライアント
│   │       ├── FirebaseService.swift  # Firestore CRUD
│   │       └── Secrets.swift          # APIキー（gitignore済）
│   └── Features/
│       ├── Timeline/
│       │   ├── TimelineView.swift     # タイムライン画面
│       │   └── PostCardView.swift     # 投稿カード
│       ├── Post/
│       │   └── PostView.swift         # 日記投稿・エール受け取り画面
│       └── Profile/
│           └── ProfileView.swift      # マイページ
├── Resources/
│   └── GoogleService-Info.plist   # Firebase設定（gitignore済）
└── Tests/
```

---

## 開発状況

### 実装済み
- [x] SwiftUI タブナビゲーション
- [x] タイムライン（Firebase 未設定時はモック、ログイン後は Firestore フェッチを試行）
- [x] 日記投稿UI
- [x] フィードバックモード選択（4モード）
- [x] Claude API 連携
- [x] モック/本番APIの自動切替
- [x] リアクションUI
- [x] Firebase SDK セットアップ（plist配置待ち）
- [x] Firebase Auth（Apple）・オンボーディング画面
- [x] Firestore Rules / Storage Rules ファイル（デプロイは Firebase CLI）
- [x] Homeのローカル+Firestore同期（取得マージ/保存）
- [x] 投稿保存・リアクション追加のTODO解消
- [x] Free/Premium機能ゲート（日記回数・着せ替え・月次ダウンロード）
- [x] StoreKit 2 基本導線（購入/復元・判定反映）

### 実装予定
- [ ] Firestore 連携の本格化（プロフィール同期、リアクション集計読込など）
- [ ] フォロー機能
- [ ] AI会話モード
- [ ] ストリーク
- [ ] プッシュ通知
- [ ] サブスクリプション本番化（App Store Connect商品ID確定 / レシート検証）

---

App Store 公開の手順は [.claude/docs/app-store-release.md](.claude/docs/app-store-release.md) を参照。

---

## ライセンス

Private
