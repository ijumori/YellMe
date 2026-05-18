#!/usr/bin/env bash
# スクショ（ある分だけ・最大10枚）+ アプリプレビューを ASC へ投稿
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
export PATH="/opt/homebrew/opt/ruby/bin:${PATH:-}"

PREVIEW_ROOT="$ROOT/AppStoreMetadata/deliver/app-previews"
PREVIEW_SKIP="${PREVIEW_ROOT}._upload_skip"

deliver_common() {
  bundle exec fastlane deliver \
    --app_identifier "com.takahiro.yellme" \
    --username "ijumorimori@gmail.com" \
    --skip_binary_upload true \
    --skip_metadata true \
    --force true \
    --run_precheck_before_submit false \
    --precheck_include_in_app_purchases false \
    "$@"
}

echo "===== 1/3 スクショ生成（iCloud写真 → deliver） ====="
if [[ -x "$ROOT/.venv-screenshots/bin/python" ]]; then
  "$ROOT/.venv-screenshots/bin/python" "$ROOT/scripts/build_asc_screenshots_from_icloud.py"
else
  python3 "$ROOT/scripts/build_asc_screenshots_from_icloud.py"
fi

IPHONE_COUNT=$(find "$ROOT/AppStoreMetadata/deliver/screenshots/ja/iPhone XS Max" -maxdepth 1 -name '*.png' 2>/dev/null | wc -l | tr -d ' ')
IPAD_COUNT=$(find "$ROOT/AppStoreMetadata/deliver/screenshots/ja/iPad Pro (12.9-inch) (3rd generation)" -maxdepth 1 -name '*.png' 2>/dev/null | wc -l | tr -d ' ')
echo "スクショ: iPhone ${IPHONE_COUNT} 枚, iPad ${IPAD_COUNT} 枚（最大10枚まで ASC 可）"

if [[ "$IPHONE_COUNT" -eq 0 ]]; then
  echo "❌ スクショがありません。iCloud写真/ に PNG を置いてください。" >&2
  exit 1
fi

echo "===== 2/3 スクショを ASC へアップロード ====="
if [[ -d "$PREVIEW_ROOT" ]]; then
  mv "$PREVIEW_ROOT" "$PREVIEW_SKIP"
fi
deliver_common \
  --skip_screenshots false \
  --screenshots_path "AppStoreMetadata/deliver/screenshots" \
  --overwrite_screenshots true
if [[ -d "$PREVIEW_SKIP" ]]; then
  mv "$PREVIEW_SKIP" "$PREVIEW_ROOT"
fi

echo "===== 3/3 アプリプレビューを ASC へ（デバイス別・順次） ====="
if [[ ! -f "$ROOT/AppStoreMetadata/app-previews/ja/01_intro_IPHONE_65.mp4" ]]; then
  echo "プレビュー MP4 が無いためスクリーンレコードから生成…"
  python3 "$ROOT/scripts/build_asc_previews_from_screen_recordings.py"
fi
"$ROOT/scripts/upload-app-previews-sequential.sh"

echo ""
echo "✅ スクショ + アプリプレビューの ASC 投稿が完了しました。"
