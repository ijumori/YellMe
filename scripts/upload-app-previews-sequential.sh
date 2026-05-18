#!/usr/bin/env bash
# デバイス種別ごとに App Preview を順次アップロード（並列9本での ID 無効化を避ける）
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

export PATH="/opt/homebrew/opt/ruby/bin:${PATH:-}"

PREV_DIR="$ROOT/AppStoreMetadata/deliver/app-previews/ja"
STASH="$ROOT/AppStoreMetadata/deliver/app-previews/_stash"
mkdir -p "$STASH" "$PREV_DIR"

# deliver 用 ja にある mp4 を stash へ退避（未退避分のみ）
shopt -s nullglob
for f in "$PREV_DIR"/*.mp4; do
  base=$(basename "$f")
  if [[ ! -f "$STASH/$base" ]]; then
    cp "$f" "$STASH/"
  fi
done

upload_batch() {
  local overwrite="$1"
  shift
  rm -f "$PREV_DIR"/*.mp4
  for name in "$@"; do
    cp "$STASH/$name" "$PREV_DIR/"
  done
  echo ""
  echo "===== Upload: $* (overwrite=$overwrite) ====="
  bundle exec fastlane deliver \
    --app_identifier "com.takahiro.yellme" \
    --username "ijumorimori@gmail.com" \
    --skip_binary_upload true \
    --skip_metadata true \
    --skip_screenshots true \
    --app_previews_path "AppStoreMetadata/deliver/app-previews" \
    --overwrite_preview_videos "$overwrite" \
    --force true \
    --run_precheck_before_submit false
  echo "待機 90 秒（ASC 側の処理待ち）…"
  sleep 90
}

# stash に無ければ app-previews/ja から集める
for f in "$ROOT/AppStoreMetadata/app-previews/ja"/*.mp4; do
  [[ -f "$f" ]] || continue
  base=$(basename "$f")
  [[ -f "$STASH/$base" ]] || cp "$f" "$STASH/"
done

upload_batch true \
  "01_intro_IPHONE_65.mp4" "02_record_IPHONE_65.mp4" "03_yell_IPHONE_65.mp4"

upload_batch true \
  "01_intro_IPHONE_67.mp4" "02_record_IPHONE_67.mp4" "03_yell_IPHONE_67.mp4"

upload_batch true \
  "01_intro_IPAD_PRO_3GEN_129.mp4" "02_record_IPAD_PRO_3GEN_129.mp4" "03_yell_IPAD_PRO_3GEN_129.mp4"

cp "$STASH"/*.mp4 "$PREV_DIR"/
echo "完了: 全プレビューを deliver/ja に復元しました。"
