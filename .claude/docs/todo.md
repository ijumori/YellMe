# 未実装TODO

## Phase 1（完了）
- [x] Firebase Auth（Apple Sign In）
- [x] オンボーディング画面
- [x] Firestore日次記録CRUD（基本保存/取得）
- [x] プロフィール編集（表示名・自己紹介）

## Phase 2
- [ ] AI会話モード
- [ ] ストリーク表示の強化（UIバッジ等）
- [ ] プッシュ通知（FCM）

## Phase 3（基本完了）
- [x] StoreKit 2 サブスクリプション（購入・復元・ゲート）
- [x] AIエール回数制限（Free 1 / Premium 3）
- [x] プレミアム機能ロック（着せ替え/月次DL）
- [ ] アバター着せ替えUI実装

## 品質・テスト
- [x] SwiftLint 設定（`.swiftlint.yml`）
- [x] Unit Test（`DailyJournalStoreTests` 3件）
- [x] UI Test ターゲット（`YellMeUITests` 2件）
- [ ] テストカバレッジ拡大（ViewModel / ClaudeService）

## App Store
- [x] プライバシーポリシー・サポートページ・利用規約公開（GitHub Pages）
- [x] サブスク詳細・法的リンクをアプリ内に追加（ProfileView）
- [x] App Store 説明文にサブスク自動更新条件追記
- [x] iPad クラッシュ対応（TARGETED_DEVICE_FAMILY=1、iPhone専用化）
- [x] v1.0.0 公開（build 7）
- [x] v1.0.1 メタデータ更新・審査提出（build 8）
- [ ] v1.0.1 審査通過待ち
