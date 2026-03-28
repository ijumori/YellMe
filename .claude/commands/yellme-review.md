# yellme-review — Swift コードセルフレビュー

直近で変更した Swift ファイル（またはユーザーが指定したファイル）を以下の観点でレビューし、問題点と改善提案をリストアップしてください。

## レビュー観点

### 1. アーキテクチャ
- [ ] ViewModelが `@MainActor class XxxViewModel: ObservableObject` パターンに準拠しているか
- [ ] ViewとViewModelが同ファイルに共存しているか（別ファイル分離はNG）
- [ ] ServiceがUIに直接依存していないか

### 2. Swift Concurrency安全性
- [ ] Serviceが `actor` として定義されているか
- [ ] `await` 忘れ・`Task` のキャンセル漏れがないか
- [ ] `@MainActor` なしでUI更新していないか

### 3. モデル設計
- [ ] モデルが `Codable` + `Equatable` に準拠しているか
- [ ] `.animation(value:)` を使う型がすべて `Equatable` か
- [ ] FirestoreモデルへのFirestore依存混入がないか（DTO経由になっているか）

### 4. セキュリティ
- [ ] APIキー・シークレットがハードコードされていないか
- [ ] `Secrets.claudeAPIKey` が直接コード内に埋め込まれていないか

### 5. SwiftUI品質
- [ ] `@StateObject` / `@ObservedObject` の使い分けが正しいか
- [ ] UIKit APIが混入していないか
- [ ] 不要な `body` 再評価を招くコードがないか

## 出力フォーマット

問題なし → 「✅ レビュー通過」と一言
問題あり → 以下の形式で列挙:

```
⚠️ [ファイル名:行番号] 問題の概要
   理由: ...
   修正案: ...
```

最後に総評（1〜2文）を追加してください。
