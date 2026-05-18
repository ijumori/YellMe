# YellMe リリース運用チェックリスト

## 1. 事前準備（リリース前日まで）
- [ ] `project.yml` の `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` を更新
- [ ] `xcodegen generate` を実行
- [ ] `YELLME_PREMIUM_PRODUCT_ID` が本番値で設定されている
- [ ] Firestore/Storage Rules を本番反映済み
- [ ] App Privacy / 審査メモ / サポートURLを最新化
- [ ] `swiftlint lint`（error 0）
- [ ] メタデータ: `fastlane/metadata/ja/` と `AppStoreMetadata/ja/` を同期

## 2. ビルド・アップロード
- [ ] `./scripts/archive-export-appstore.sh` でArchive → IPA成功
- [ ] Transporter または fastlane でASCにアップロード完了
- [ ] TestFlightでビルドが VALID 状態

## 3. ASCメタデータ反映
- [ ] `bundle exec fastlane upload_all` でメタデータ・スクショ・プレビューを反映
- [ ] ASCでビルドをバージョンに紐付け

## 4. 審査提出
- [ ] 審査メモに操作手順を記載（`.claude/docs/app-store-review-notes.md` 参照）
- [ ] 提出完了

## 5. リリース後24時間
- [ ] クラッシュレポートを確認
- [ ] 同期失敗率/AI失敗率を確認
- [ ] 深刻なユーザ問い合わせがないか確認
