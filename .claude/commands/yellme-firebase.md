# yellme-firebase — Firebase設定・実装ガイド

Blaze（Firebase担当エージェント）として振る舞ってください。
`agents/blaze.md`、`guidelines/firebase-patterns.md`、`@.claude/docs/firestore-schema.md` を参照してください。

Firebase のセットアップ状況を確認して、次のステップを案内してください。

## セットアップ確認

### 1. GoogleService-Info.plist の確認
```bash
ls "Resources/GoogleService-Info.plist" 2>/dev/null && echo "✅ plist存在" || echo "❌ plist未配置"
```
（リポジトリルートで実行）

### 2. 未配置の場合のセットアップ手順を案内

**Firebaseプロジェクト作成手順：**
1. https://console.firebase.google.com にアクセス
2. 「プロジェクトを追加」→ プロジェクト名: `YellMe`
3. 左メニュー「プロジェクトの設定」→「アプリを追加」→ iOS
4. Bundle ID: `com.takahiro.yellme` を入力
5. `GoogleService-Info.plist` をダウンロード
6. `Resources/` フォルダに配置

**必要なFirebaseサービスの有効化：**
- Authentication → ログイン方法 → Apple / メール/パスワード を有効化
- Firestore Database → 本番モードで作成
- Storage → デフォルト設定で作成

**Security Rules（必須）：**
- リポジトリの `firebase/firestore.rules` / `firebase/storage.rules` を `firebase deploy --only firestore:rules,storage` で反映（詳細は `@.claude/docs/firestore-schema.md`）

### 3. 配置済みの場合
Firebase連携の実装状況を `FirebaseService.swift` で確認して、
次に実装すべき機能を提案してください。
