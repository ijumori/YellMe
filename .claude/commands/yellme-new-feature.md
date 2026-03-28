新機能の雛形ファイルを生成します。

以下を確認してから作成してください：
1. 機能名（例: Auth, Streak, Notification）
2. 必要なファイル構成をユーザーに確認する

## 標準的な生成パターン

### 新しい画面を追加する場合
`Sources/Features/{FeatureName}/` に以下を生成：

```
{FeatureName}View.swift     # SwiftUI View + ViewModel
```

### ViewModel の標準テンプレート
```swift
@MainActor
class {FeatureName}ViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetch() async {
        isLoading = true
        defer { isLoading = false }
        do {
            // 実装
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

### 新しいサービスを追加する場合
`Sources/Core/Services/{ServiceName}Service.swift` に生成

```swift
actor {ServiceName}Service {
    static let shared = {ServiceName}Service()

    // メソッド
}
```

機能名を教えてください。雛形を生成します。
