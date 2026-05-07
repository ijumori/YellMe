# YellMe 課金検証強化方針（BILL-002）

## 1. 現在方針（確定）
- 課金判定は StoreKit の **verified transaction** のみを採用する。
- `UserDefaults` の値はキャッシュ用途であり、最終判定は `currentEntitlements` と `Transaction.updates` で上書きする。
- Product ID は `Info.plist` の `YELLME_PREMIUM_PRODUCT_ID` から読み込む。

## 2. 実装済み対策
- Product ID 未設定時は `.missingProductConfiguration` で処理停止。
- 課金状態は失効日（`expirationDate`）を考慮して判定。
- 起動後とトランザクション更新時に再検証し、UIへ反映。
- Debug以外で任意プラン変更できない構成に制限。

## 3. 本番運用ルール
- 本番ビルド前に `YELLME_PREMIUM_PRODUCT_ID` を App Store Connect の実IDへ差し替える。
- リリースチェックリストで Product ID / 復元導線 / 失効時挙動を確認する。
- TestFlight で購入/復元/期限切れの3ケースを記録する。

## 4. 将来拡張（任意）
- サーバー検証を導入する場合:
  1. App Store Server API でトランザクション検証
  2. 検証結果を `users/{uid}/entitlements` に反映
  3. クライアントは表示制御のみ、権限判定はサーバー値を優先
