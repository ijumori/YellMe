# App Store メタデータの正本

| 用途 | パス | ツール |
|------|------|--------|
| **deliver 一括**（推奨） | `fastlane/metadata/ja/` | `bundle exec fastlane upload_all` |
| **ASC API パッチ** | `AppStoreMetadata/ja/` | `./scripts/upload-app-store-connect.sh --text` |
| スクショ・プレビュー | `AppStoreMetadata/deliver/` | fastlane deliver（`upload_all` / `asc_screenshots`） |

**運用**: 概要・プロモ文を変更したら `fastlane/metadata/ja/` を編集し、`AppStoreMetadata/ja/` に同内容をコピーしてからアップロードする。

```bash
cp fastlane/metadata/ja/description.txt AppStoreMetadata/ja/description.txt
cp fastlane/metadata/ja/promotional_text.txt AppStoreMetadata/ja/promotional.txt
```

## fastlane レーン一覧

| レーン | 用途 |
|--------|------|
| `upload_all` | メタデータ+スクショ+プレビュー一括（Apple ID認証） |
| `asc_screenshots` | スクショ+プレビューのみ（ASC APIキー必須） |
| `bump_build` | ASC最新ビルド番号+1でproject.yml更新 |
| `upload_build` | IPA → ASCアップロード |
| `submit_review` | メタデータ反映+審査提出 |
