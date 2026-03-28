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

# 3. Xcode プロジェクトを生成
xcodegen generate

# 4. APIキーを設定
cp Sources/Core/Services/Secrets.swift.example Sources/Core/Services/Secrets.swift
# Secrets.swift を開いて claudeAPIKey を設定

# 5. Firebase を設定（任意）
# GoogleService-Info.plist を Resources/ に配置

# 6. Xcode で開く
open YellMe.xcodeproj
```

### APIキーの設定

`Sources/Core/Services/Secrets.swift` を作成：

```swift
enum Secrets {
    static let claudeAPIKey = "sk-ant-xxxxxxxxxxxxxxxx"
}
```

> ⚠️ `Secrets.swift` は `.gitignore` に含まれています。絶対にコミットしないこと。

APIキー未設定の場合はモックデータでフィードバックが返ります。

---

## プロジェクト構成

```
YellMe/
├── project.yml                    # XcodeGen 設定
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
- [x] タイムライン（モックデータ）
- [x] 日記投稿UI
- [x] フィードバックモード選択（4モード）
- [x] Claude API 連携
- [x] モック/本番APIの自動切替
- [x] リアクションUI
- [x] Firebase SDK セットアップ（plist配置待ち）

### 実装予定
- [ ] ログイン・認証（Firebase Auth）
- [ ] オンボーディング
- [ ] Firestore 連携（投稿・ユーザーのCRUD）
- [ ] フォロー機能
- [ ] AI会話モード
- [ ] ストリーク
- [ ] プッシュ通知
- [ ] サブスクリプション（StoreKit 2）

---

## ライセンス

Private
