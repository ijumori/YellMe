# UI/UXガイドライン

## コンセプト
「批判ゼロ・共感100%のやさしい世界」をビジュアルで体現する。
UIは温かく、柔らかく、ユーザーが安心して日記を書ける雰囲気を作る。

## デザイン原則
- **温かみ**: ハードエッジより丸み（`cornerRadius: 12`〜`16`）
- **余白**: コンテンツを詰め込まない
- **フィードバック**: 操作に視覚的な反応（`.animation(value:)` は `Equatable` 必須）
- **アクセント**: タブ・主要 CTA はピンク系（`ContentView` の `.tint(.pink)`）

## SwiftUI 実装規則

```swift
.task { await viewModel.hydrateFromFirestoreIfNeeded(...) }

.animation(.spring(), value: viewModel.feedback)

NavigationStack { /* Home / History / Detail */ }
```

## エール表示（Home）
- モード別 UI: `FeedbackComponents.swift` の `FeedbackModeButton`
- 結果表示: `AIFeedbackResultView`
- モード: praise / empathy / advice / courage

## アクセシビリティ
- 装飾画像は `.accessibilityHidden(true)`、意味のある操作は `accessibilityLabel`
- UI Test 用 ID（例）: `tab_home`, `home_diary_editor`, `home_submit_button`
- タップ領域は最低 44pt（`winChip` 等）

## ナビゲーション構成（現行）

`ContentView.swift` の TabView（3タブ）:

| タブ | View | navigationTitle |
|------|------|-----------------|
| いま | `HomeView` | いま |
| きろく | `HistoryView` | きろく |
| マイページ | `ProfileView` | マイページ |

認証・オンボーディングは `RootView`（`YellMeApp.swift`）で分岐。

**きろく → マイページ**: `NavigationStack` に push せず、`ContentView` の `TabView` でマイページタブへ切り替える（日次詳細の `NavigationLink` との競合を防ぐ）。
