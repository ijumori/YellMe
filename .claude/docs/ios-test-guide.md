# YellMe テスト実行ガイド

## テストの全体像

```
Unit Test → UI Test → 静的解析 → Instruments（手動）
    ↓           ↓          ↓
 DailyJournal  タブ/記録   SwiftLint + Analyze
```

## ターゲット（本リポジトリ）

| ターゲット | パス | 内容 |
|-----------|------|------|
| `YellMeTests` | `Tests/` | `DailyJournalStoreTests`（3件） |
| `YellMeUITests` | `UITests/` | タブ遷移・日記入力（2件） |

UI Test 起動時は `-ui-testing` で UserDefaults をリセット（`UITestingSupport.swift`）。

---

## STEP 1: 静的解析

```bash
brew install swiftlint   # 未導入時
swiftlint lint           # .swiftlint.yml（Sources / Tests / UITests）
```

Xcode: **Product → Analyze**（⇧⌘B）

ターミナル:

```bash
xcodebuild analyze -project YellMe.xcodeproj -scheme YellMe \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'
```

---

## STEP 2: Unit Test

Xcode: **⌘U**

ターミナル:

```bash
xcodegen generate
rm -rf build/TestResults.xcresult
xcodebuild test -project YellMe.xcodeproj -scheme YellMe \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -enableCodeCoverage YES \
  -resultBundlePath build/TestResults.xcresult
```

---

## STEP 3: UI Test

- 録画: `UITests/YellMeUITests.swift` を開き、テスト内で **● Record**
- 識別子: `tab_home` / `tab_history` / `tab_profile` / `home_diary_editor` / `home_submit_button` / `history_open_profile`
- 回帰: `testHistoryDetailAfterProfileShortcut`（きろく→詳細→マイページショートカット→きろく→詳細）

---

## STEP 4〜5: Instruments・実機ログ

- **⌘I** → Leaks
- **Window → Devices and Simulators** → View Device Logs

---

## STEP 6: カバレッジ

**Product → Scheme → Edit Scheme → Test → Code Coverage** をオン → **⌘U** → **⌘9** → Coverage

---

## チェックリスト

- [ ] `swiftlint lint`（error 0）
- [ ] Analyze 成功
- [ ] Unit Test 3件成功
- [ ] UI Test 2件成功
- [ ] 実機 Run（⌘R）で主要タブ確認
- [ ] Instruments（Leaks）— 任意
