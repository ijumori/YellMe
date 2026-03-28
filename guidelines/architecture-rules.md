# アーキテクチャルール

## 基本原則
- アーキテクチャ: **MVVM**（Model / ViewModel / View の3層厳守）
- UI: **SwiftUI onlyで実装**（UIKit導入は原則禁止）
- 並行処理: **Swift Concurrency**（async/await / actor）

## MVVM層の分離
```
View          → 表示のみ。ロジックを持たない
ViewModel     → UIロジック・状態管理。@Published で View に公開
Service       → ビジネスロジック・外部通信（Firebase/Claude API）
Model         → データ構造のみ。UIもServiceも知らない
```

## ファイル配置
```
Features/{Name}/{Name}View.swift   → View + ViewModel（同ファイル）
Core/Services/{Name}Service.swift  → Service（actor）
Core/Models/{Name}.swift           → Model（Codable + Equatable）
```

## ViewModel定型
```swift
@MainActor
class XxxViewModel: ObservableObject {
    @Published var items: [Item] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
}
```

## Service定型
```swift
actor XxxService {
    // UI依存なし。Modelも直接持たない（DTO経由）
}
```

## XcodeGen
- `.xcodeproj` は**直接編集しない**
- SPM追加・ターゲット変更 → `project.yml` → `xcodegen generate`

## 禁止事項
- View内にビジネスロジックを書く
- ServiceにUIフレームワーク（SwiftUI/UIKit）をimportする
- ViewModel を actor にする（MainActor の class のみ）
