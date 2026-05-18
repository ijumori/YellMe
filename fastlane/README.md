fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios asc_screenshots

```sh
[bundle exec] fastlane ios asc_screenshots
```

スクショ + アプリプレビュー動画をアップロード（メタデータは変更しない）。fastlane 2.234+ 必須。

### ios upload_all

```sh
[bundle exec] fastlane ios upload_all
```

Apple ID 認証でスクショ + プレビュー + メタデータを一括アップロード

### ios bump_build

```sh
[bundle exec] fastlane ios bump_build
```

App Store Connect の最新ビルド番号を取得して +1 し、project.yml を更新 → xcodegen generate

### ios upload_build

```sh
[bundle exec] fastlane ios upload_build
```

Archive 済み IPA を App Store Connect にアップロード（API キー優先、なければ Apple ID + アプリ用パスワード）

### ios submit_review

```sh
[bundle exec] fastlane ios submit_review
```

メタデータを反映し審査へ提出（ビルドは ASC で選択済みであること）

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
