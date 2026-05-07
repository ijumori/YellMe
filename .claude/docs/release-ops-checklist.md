# YellMe リリース運用チェックリスト

## 1. 事前準備（リリース前日まで）
- [ ] `project.yml` の `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` を更新
- [ ] `xcodegen generate` を実行し、`YellMe.xcodeproj` を再生成
- [ ] `YELLME_PREMIUM_PRODUCT_ID` が本番値で設定されている
- [ ] Firestore/Storage Rules を本番反映済み
- [ ] App Privacy / 審査メモ / サポートURLを最新化

## 2. リリース当日
- [ ] ReleaseビルドのArchive成功
- [ ] Validate Appで重大エラーなし
- [ ] App Store Connectへアップロード完了
- [ ] TestFlight内部テスト（主要導線）完了
- [ ] 既知の制約を審査ノートに記載

## 3. Go/No-Go 判定
- [ ] P0/P1の未解決障害が0件
- [ ] クラッシュ再現ケースの未対応がない
- [ ] セキュリティ懸念（認可/機密漏えい）が解消済み
- [ ] ロールバック手順が最新コミットに対応している

## 4. リリース後24時間
- [ ] クラッシュレポートを確認（0件または許容範囲）
- [ ] 同期失敗率/AI失敗率を確認
- [ ] 深刻なユーザ問い合わせがないか確認
- [ ] 必要ならHotfixチケットを即時起票

## 5. ロールバックメモ
- 安定版タグ: `release-stable-baseline`
- 担当: Release Agent（実施） + Chief（承認）
- 目標復旧時間: 30分以内
