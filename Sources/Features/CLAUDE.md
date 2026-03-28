# Features レイヤー規則

## ファイル構成
- 1画面1ファイル: `{Name}/{Name}View.swift`
- ViewModelは**同ファイル末尾**に配置（別ファイル不可）

## ViewModelテンプレート
```swift
@MainActor
class XxxViewModel: ObservableObject {
    @Published var items: [Item] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load() async { ... }
}
```

## SwiftUI規則
- `@StateObject` は画面オーナー、`@ObservedObject` は受け取り側
- `.animation(value:)` を使う型は必ず `Equatable` 準拠
- UIKit不使用。SwiftUI onlyで実装

## ナビゲーション
- TabViewルートは `ContentView.swift` で管理
- 画面遷移は `NavigationStack` + `navigationDestination`
