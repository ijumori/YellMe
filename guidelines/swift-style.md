# Swift コーディングスタイル

## 命名規則
| 対象 | スタイル | 例 |
|------|---------|---|
| 型（class/struct/enum） | UpperCamelCase | `PostCardView` |
| 変数・関数 | lowerCamelCase | `isLoading`, `fetchPosts()` |
| 定数 | lowerCamelCase | `let apiKey` |
| enum case | lowerCamelCase | `.praise`, `.empathy` |

## モデル設計
- **必須準拠**: `Codable` + `Equatable`
- `Equatable` 忘れ → `.animation(value:)` コンパイルエラーになる
- `Identifiable` は `id: String = UUID().uuidString` で対応

```swift
struct Post: Codable, Equatable, Identifiable {
    let id: String
    let content: String
    // ...
}
```

## @StateObject vs @ObservedObject
- `@StateObject`: その View が ViewModel のオーナー（作る側）
- `@ObservedObject`: 上位から受け取る（受け取る側）
- `@EnvironmentObject`: アプリ全体で共有する場合のみ

## async/await
- `Task { await viewModel.load() }` は `.onAppear` 内で使う
- `Task` はキャンセル漏れに注意（`.task {}` modifier を優先）

```swift
.task {
    await viewModel.fetchPosts()
}
```

## エラーハンドリング
```swift
do {
    try await service.save(post)
} catch {
    errorMessage = error.localizedDescription
}
```

## 禁止
- `!`（強制アンラップ）の使用（`guard let` / `if let` を使う）
- `DispatchQueue.main.async`（`@MainActor` / `await MainActor.run` を使う）
- `UIKit` の import
