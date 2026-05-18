#!/usr/bin/env bash
# App Store Connect へ
#   - スクリーンショット + アプリプレビュー動画（fastlane deliver）
#   - 概要・プロモーション文（REST API PATCH）
#
# 事前準備:
#   App Store Connect → ユーザーとアクセス → 鍵 → App Manager 以上で API 鍵を作成し .p8 を保存
#
# 環境変数（archive-export-appstore.sh --upload と同じ）:
#   ASC_API_ISSUER_ID   Issuer ID
#   ASC_API_KEY_ID      鍵 ID
#   ASC_API_KEY_PATH    AuthKey_XXX.p8 のパス
#
# 使い方:
#   ./scripts/upload-app-store-connect.sh --all
#   ./scripts/upload-app-store-connect.sh --screenshots
#   ./scripts/upload-app-store-connect.sh --text
#   ./scripts/upload-app-store-connect.sh --text --dry-run
#
# 注意: 既存の別デバイスサイズのスクショは既定では削除しません。
#       アプリプレビューは AppStoreMetadata/app-previews/ja/*.mp4 が無いと生成を試みます（ffmpeg + Pillow 要）。
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# fastlane 2.234+ は Ruby 2.7+ 必須。Homebrew Ruby を優先（/usr/bin/ruby は 2.6 のことが多い）
if [[ -x /opt/homebrew/opt/ruby/bin/bundle ]]; then
  export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
elif [[ -x /usr/local/opt/ruby/bin/bundle ]]; then
  export PATH="/usr/local/opt/ruby/bin:$PATH"
fi

DO_SCREEN=false
DO_TEXT=false
DRY_RUN=false

usage() {
  sed -n '2,30p' "$0" | tail -n +1
}

for a in "$@"; do
  case "$a" in
    -h|--help) usage; exit 0 ;;
    --all) DO_SCREEN=true; DO_TEXT=true ;;
    --screenshots) DO_SCREEN=true ;;
    --text) DO_TEXT=true ;;
    --dry-run) DRY_RUN=true ;;
    *) echo "Unknown option: $a" >&2; usage; exit 2 ;;
  esac
done

if ! $DO_SCREEN && ! $DO_TEXT; then
  echo "--screenshots / --text / --all のいずれかを指定してください。" >&2
  exit 2
fi

for v in ASC_API_ISSUER_ID ASC_API_KEY_ID ASC_API_KEY_PATH; do
  if [[ -z "${!v:-}" ]]; then
    echo "環境変数 $v が未設定です。" >&2
    exit 1
  fi
done

DELIVER_BASE="$ROOT/AppStoreMetadata/deliver"
SCREEN_DST="$DELIVER_BASE/screenshots/ja"
PRE_DST="$DELIVER_BASE/app-previews/ja"
IPHONE_DIR="iPhone XS Max"
IPAD_DIR='iPad Pro (12.9-inch) (3rd generation)'

if $DO_SCREEN; then
  SRC_IPHONE="$ROOT/AppStoreMetadata/screenshots/iphone65"
  SRC_IPAD="$ROOT/AppStoreMetadata/screenshots/ipad13"
  if [[ ! -d "$SRC_IPHONE" || ! -d "$SRC_IPAD" ]]; then
    echo "スクショ元がありません。先に: python3 scripts/generate_app_store_screenshots.py" >&2
    exit 1
  fi

  PRE_SRC="$ROOT/AppStoreMetadata/app-previews/ja"
  if [[ ! -d "$PRE_SRC" ]] || ! ls "$PRE_SRC"/*.mp4 &>/dev/null; then
    echo "アプリプレビュー .mp4 が無いため scripts/generate_app_store_previews.py を実行します…"
    if [[ -x "$ROOT/.venv-screenshots/bin/python3" ]]; then
      "$ROOT/.venv-screenshots/bin/python3" "$ROOT/scripts/generate_app_store_previews.py" || {
        echo "ヒント: brew install ffmpeg && python3 -m venv .venv-screenshots && .venv-screenshots/bin/pip install Pillow" >&2
      }
    else
      python3 "$ROOT/scripts/generate_app_store_previews.py" || {
        echo "ヒント: brew install ffmpeg && pip install Pillow" >&2
      }
    fi
  fi

  rm -rf "$DELIVER_BASE"
  mkdir -p "$SCREEN_DST/$IPHONE_DIR" "$SCREEN_DST/$IPAD_DIR"
  cp "$SRC_IPHONE"/*.png "$SCREEN_DST/$IPHONE_DIR/"
  cp "$SRC_IPAD"/*.png "$SCREEN_DST/$IPAD_DIR/"
  echo "deliver 用にコピーしました: $SCREEN_DST"

  if [[ -d "$PRE_SRC" ]] && ls "$PRE_SRC"/*.mp4 &>/dev/null; then
    mkdir -p "$PRE_DST"
    cp "$PRE_SRC"/*.mp4 "$PRE_DST/"
    echo "アプリプレビューをコピーしました: $PRE_DST"
  else
    echo "（アプリプレビュー .mp4 なし — 動画のみスキップ）" >&2
  fi
fi

if $DO_SCREEN; then
  if ! command -v bundle &>/dev/null; then
    echo "Bundler (bundle コマンド) が必要です。例: gem install bundler" >&2
    exit 1
  fi
  bundle install --path "$ROOT/vendor/bundle" --quiet
  bundle exec fastlane asc_screenshots
fi

if $DO_TEXT; then
  PY="$ROOT/.venv-asc/bin/python3"
  if [[ ! -x "$PY" ]]; then
    python3 -m venv "$ROOT/.venv-asc"
    "$ROOT/.venv-asc/bin/pip" install -q -r "$ROOT/scripts/requirements-asc.txt"
    PY="$ROOT/.venv-asc/bin/python3"
  fi
  EXTRA=()
  if $DRY_RUN; then
    EXTRA+=(--dry-run)
  fi
  "$PY" "$ROOT/scripts/asc_patch_localization.py" "${EXTRA[@]}"
fi

echo "完了。"
