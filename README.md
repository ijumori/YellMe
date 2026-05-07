# エールミー (YellMe)

> 書くたびに、少し自分が好きになれる。

日記を書くと、AIが必ず褒めポイントを見つけてフィードバックしてくれる個人記録アプリ。
批判ゼロ・共感100%の「やさしい世界」を提供する。

---

## プロダクトイメージ

エールミーは、日々の記録を通して「自分の心を整える」ための個人アプリです。  
ユーザーは日記と「今日できたこと」を記録し、AIコンパニオンからやさしいフィードバックを受け取ります。

- **個人記録が主役**: 他人との比較や評価が入らない、自己完結の体験
- **AIは友達のような存在**: 批判せず、共感と励ましでそっと伴走
- **成長の実感**: 記録を続けるほどキャラクターが進化し、関係性が深まる
- **目指す価値**: 悩みや不安をゼロに断定するのではなく、気持ちを軽くして前を向ける状態をつくる

体験の基本ループ:

`記録する -> AIが寄り添って返す -> キャラクターが育つ -> また書きたくなる`

---

## スクリーンショット

| いま | きろく | マイページ |
|------|--------|-----------|
| （準備中） | （準備中） | （準備中） |

---

## 機能

- **日記投稿** — テキストで今日の出来事を書く
- **AIエール（4モード）** — 褒めて / 共感して / アドバイスして / 勇気をくれ
- **今日できたこと** — 体調・くらし・こころ・ひと の小さな達成を記録
- **記録履歴** — 月別に過去の日記とAIエールを振り返り
- **マイページ** — 自分専用の設定・プラン管理
- **コンパニオン進化演出** — 段階アップ時に進化イベントを通知

---

## 技術スタック

| 項目 | 内容 |
|------|------|
| プラットフォーム | iOS 17.0+ |
| 言語 | Swift 5.9 |
| UI | SwiftUI |
| アーキテクチャ | MVVM |
| AI | Claude API（claude-sonnet-4-6） |
| バックエンド | Firebase（Auth / Firestore） |
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
- `users/{uid}/dailyEntries/{yyyy-MM-dd}` は本人のみ read/write、`submissionCount` の不正減算をRulesで拒否
- Storage は `users/{uid}/**` を本人のみ read/write（他人ファイル参照不可）
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
- [x] Home（いま）日次記録UI
- [x] フィードバックモード選択（4モード）
- [x] Claude API 連携
- [x] モック/本番APIの自動切替
- [x] 記録履歴（きろく）一覧・詳細
- [x] Firebase SDK セットアップ（plist配置待ち）
- [x] Firebase Auth（Apple）・オンボーディング画面
- [x] Firestore Rules / Storage Rules ファイル（デプロイは Firebase CLI）
- [x] Homeのローカル+Firestore同期（取得マージ/保存）
- [x] Free/Premium機能ゲート（日記回数・着せ替え・月次ダウンロード）
- [x] StoreKit 2 基本導線（購入/復元・判定反映）

### 実装予定
- [ ] Firestore 連携の本格化（プロフィール同期など）
- [ ] AI会話モード
- [ ] ストリーク
- [ ] プッシュ通知
- [ ] サブスクリプション本番化の最終反映（App Store Connect実Product ID投入）

---

App Store 公開の手順は [.claude/docs/app-store-release.md](.claude/docs/app-store-release.md) を参照。

---

## ライセンス

Private
