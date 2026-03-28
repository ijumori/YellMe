エールミープロジェクトの現状を診断してください。

以下の項目を順番に確認して報告してください：

## 1. ビルド状態
```bash
cd "/Users/takahironishii/マイドライブ/04.Dev/YellMe" && \
xcodebuild -project YellMe.xcodeproj -scheme YellMe \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build 2>&1 | tail -5
```

## 2. ファイル構成チェック
必須ファイルの存在確認：
- `Sources/Core/Services/Secrets.swift`
- `Resources/GoogleService-Info.plist`（Firebaseセットアップ済みか）
- `project.yml`

## 3. TODO確認
CLAUDE.md の「未実装・TODO」セクションを読んで残タスクを報告

## 4. 診断サマリー
- ✅ 正常な項目
- ⚠️ 注意が必要な項目
- ❌ 対応が必要な問題

をまとめて報告してください。
