# UI/UXガイドライン

## コンセプト
「批判ゼロ・共感100%のやさしい世界」をビジュアルで体現する。
UIは温かく、柔らかく、ユーザーが安心して日記を書ける雰囲気を作る。

## デザイン原則
- **温かみ**: ハードエッジより丸みを使う（`cornerRadius: 16` 以上）
- **余白**: コンテンツを詰め込まない。`.padding()` を惜しまない
- **フィードバック**: 操作に対して必ず視覚的な反応を返す
- **アニメーション**: 意味のある動きだけ。装飾的なアニメーションは避ける

## カラー方針
- システムカラー（`.systemBackground`, `.label`）を基本とし、ダークモードを自動対応
- アクセントカラーはAssets.xcassetsで管理（ハードコード禁止）

## SwiftUI 実装規則
```swift
// ✅ .task を優先（キャンセル自動処理）
.task { await viewModel.load() }

// ✅ animation は value ベース（Equatable 必須）
.animation(.spring(), value: isExpanded)

// ✅ 画面遷移は NavigationStack
NavigationStack {
    // ...
    .navigationDestination(for: Post.self) { post in
        PostDetailView(post: post)
    }
}
```

## フィードバックバブル（PostCardView）
- モード別カラー:
  - `.praise` → 暖色（オレンジ/イエロー系）
  - `.empathy` → 寒色（ブルー/パープル系）
  - `.advice` → グリーン系
  - `.courage` → ピンク/レッド系
- バブルの出現は `.transition(.scale.combined(with: .opacity))` で

## アクセシビリティ
- すべての画像に `.accessibilityLabel` を設定
- フォントは Dynamic Type 対応（`Font.body`, `Font.title2` 等を使う）
- タップ領域は最低44×44pt

## ナビゲーション構成
- ルート: `ContentView.swift` の TabView（3タブ）
  - タブ1: タイムライン（`TimelineView`）
  - タブ2: 書く（`PostView`）
  - タブ3: マイページ（`ProfileView`）
