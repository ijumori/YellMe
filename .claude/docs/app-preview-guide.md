# App Store Preview 制作ガイド

YellMe のアプリプレビュー動画・スクリーンショット制作の実践ガイド。
最終更新: 2026-05-12

---

## 1. 基本方針

**最適構成: 実画面録画 + AI編集補助**
SoraやVeoを全面使用するより、審査に通りやすく修正も速い。

| 工程 | ベストツール | 備考 |
|------|-------------|------|
| 画面録画 | **Xcode Simulator** | `xcrun simctl io` で録画 |
| AI補助編集 | Runway | 背景補正・ノイズ除去など |
| テロップ追加 | Descript | テキストオーバーレイ |
| 軽編集 | CapCut | トリミング・トランジション |
| Apple形式調整 | ffmpeg / AppPreviewCut | 解像度・fps・コーデック変換 |

---

## 2. Apple の技術要件

### プレビュー動画

| 項目 | iPhone 6.5" / 6.7" | iPad 13" |
|------|---------------------|----------|
| 解像度 | 886 x 1920 | 1200 x 1600 |
| フレームレート | **30fps 以上（必須）** | 同左 |
| 動画長 | 15〜30秒 | 同左 |
| コーデック | H.264 High Profile | 同左 |
| 音声 | **AAC 必須**（無音でもトラック必要） | 同左 |
| 本数 | 最大3本/デバイスサイズ | 同左 |

### スクリーンショット

| デバイス | 解像度 | 枚数 |
|---------|--------|------|
| iPhone 6.5" | 1284 x 2778 | 3〜10枚 |
| iPad 13" | 2048 x 2732 | 3〜10枚 |

---

## 3. App Review で NG になること

**絶対にやってはいけないこと:**

- 実際に存在しない UI を表示する
- 過剰な AI 演出（実機と異なる動作）
- 実機挙動との差異がある映像
- 誇張アニメーション
- 存在しない機能の表現

> **Apple は「マーケ映像」より「実際の使用フロー」を重視。**
> プレビューは実際のアプリの動作を忠実に反映する必要がある。

---

## 4. 本格フロー — 実践手順

### Step 1: シミュレータ起動 & アプリビルド

```bash
# iPhone 17 Pro Max（6.7" → 6.5" 互換）
xcrun simctl boot "A2338C1F-96BD-4B7A-BEF0-7C64331D0A05"
open -a Simulator

# アプリをビルド＆インストール
cd "/Users/takahironishii/マイドライブ（ijumorimori@gmail.com）/04.Dev/YellMe"
xcodebuild -project YellMe.xcodeproj -scheme YellMe \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,id=A2338C1F-96BD-4B7A-BEF0-7C64331D0A05' \
  build

# iPad Pro 13" も必要な場合
xcrun simctl boot "7AD0631D-AAE8-4302-A882-B2015940BE94"
```

### Step 2: 画面録画（3本）

自動化スクリプトを使用:

```bash
# iPhone のみ（対話式 — 指示に従って操作）
./scripts/record-app-preview.sh

# iPad も録画
./scripts/record-app-preview.sh --ipad
```

または手動で録画:

```bash
# 録画開始（Ctrl+C で停止）
xcrun simctl io booted recordVideo --codec=h264 preview_01.mov

# 3本分の操作フロー:
# 01_intro: アプリ起動 → ホーム画面 → コンパニオン表示
# 02_record: 日記入力 → できたことチップ選択 → 送信
# 03_yell: エール表示 → スクロール → きろくタブ
```

### Step 3: Apple 要件に変換（ffmpeg）

自動変換（録画スクリプト使用時は自動実行）:

```bash
# 録画済みファイルから変換のみ
./scripts/record-app-preview.sh --convert
```

手動変換:

```bash
# iPhone 6.5" 用（886x1920, 30fps, AAC音声付き）
ffmpeg -y -i raw/01_intro_iphone.mov \
  -f lavfi -i "anullsrc=channel_layout=stereo:sample_rate=44100" \
  -r 30 \
  -vf "scale=886:1920:force_original_aspect_ratio=decrease,pad=886:1920:(ow-iw)/2:(oh-ih)/2,format=yuv420p" \
  -c:v libx264 -profile:v high -pix_fmt yuv420p \
  -c:a aac -b:a 128k \
  -shortest -t 30 \
  -movflags +faststart \
  01_intro_IPHONE_65.mp4

# iPad 13" 用 → scale を 1200:1600 に変更
```

### Step 4: 検証

```bash
# 全動画のスペック確認
for f in AppStoreMetadata/app-previews/ja/*.mp4; do
  echo "$(basename $f):"
  ffprobe -v error -select_streams v:0 \
    -show_entries stream=width,height,r_frame_rate -of csv=p=0 "$f"
  ffprobe -v error -select_streams a:0 \
    -show_entries stream=codec_name -of csv=p=0 "$f"
done
```

**チェックリスト:**

- [ ] 解像度: iPhone 886x1920 / iPad 1200x1600
- [ ] フレームレート: 30/1 fps
- [ ] 音声: aac
- [ ] 長さ: 15〜30秒

### Step 5: ASC にアップロード

```bash
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
bundle exec fastlane upload_all
```

または ASC Web 画面からドラッグ&ドロップでアップロード。

---

## 5. ファイル構成

```
AppStoreMetadata/
├── app-previews/
│   ├── raw/                     # 録画元ファイル（.mov）
│   └── ja/                      # 変換済み（.mp4） — ASCアップロード元
│       ├── 01_intro_IPHONE_65.mp4
│       ├── 01_intro_IPHONE_67.mp4
│       ├── 01_intro_IPAD_PRO_3GEN_129.mp4
│       ├── 02_record_*.mp4
│       └── 03_yell_*.mp4
├── screenshots/
│   ├── iphone65/                # iPhone 6.5" スクショ（1284x2778）
│   └── ipad13/                  # iPad 13" スクショ（2048x2732）
├── deliver/                     # fastlane deliver 用コピー
│   ├── screenshots/ja/
│   │   ├── iPhone XS Max/
│   │   └── iPad Pro (12.9-inch) (3rd generation)/
│   └── app-previews/ja/
└── ja/
    ├── description.txt          # ASC 概要
    └── promotional.txt          # ASC プロモーションテキスト

scripts/
├── record-app-preview.sh        # 本格フロー（録画→変換→配置）
├── generate_screenshots_v2.py   # 実スクショ + モック生成
└── generate_app_store_previews.py  # モックスライド動画（暫定用）
```

---

## 6. 過去の問題と解決策

| 問題 | 原因 | 解決策 |
|------|------|--------|
| 「オーディオがサポートされていないか、破損」 | 音声トラックがない MP4 | ffmpeg で `anullsrc` の無音 AAC トラックを追加 |
| 「フレームレートが低すぎます」 | 0.2fps（5秒に1フレーム） | ffmpeg に `-r 30` を追加して 30fps 出力 |
| fastlane deliver で Preview アップロード失敗 | リソースID無効化（長時間アップロード中にタイムアウト） | ASC Web から壊れた Preview Set を削除してリトライ |
| ASC API 403 Forbidden | API キーが読み取り専用（Developer ロール） | App Manager 以上に変更、または Apple ID 認証で fastlane 使用 |

---

*YellMe (com.takahiro.yellme) | Team: NXFZ5AUX62*
