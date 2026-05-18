#!/usr/bin/env bash
# ================================================================
# App Store プレビュー動画 — 本格フロー
#
# 使い方:
#   1. シミュレータでアプリを開いた状態で実行
#   2. 指示に従って操作（各15〜30秒）
#   3. Enter で録画停止
#   4. 全3本録画後、自動で Apple 要件に変換
#
#   ./scripts/record-app-preview.sh              # iPhone のみ
#   ./scripts/record-app-preview.sh --ipad       # iPad も録画
#   ./scripts/record-app-preview.sh --convert    # 変換のみ（録画済みファイルから）
# ================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RAW_DIR="$ROOT/AppStoreMetadata/app-previews/raw"
OUT_DIR="$ROOT/AppStoreMetadata/app-previews/ja"
DELIVER_DIR="$ROOT/AppStoreMetadata/deliver/app-previews/ja"

# Apple 要件
IPHONE_SIZE="886:1920"
IPAD_SIZE="1200:1600"
FPS=30

mkdir -p "$RAW_DIR" "$OUT_DIR" "$DELIVER_DIR"

# --- 3 本のプレビューテーマ ---
THEMES=(
  "01_intro|はじめに — アプリを開いてホーム画面を見せる → コンパニオンを見せる → 日付を確認"
  "02_record|記録する — 日記を入力 → できたことチップを選択 → 送信"
  "03_yell|エールを見る — エールが届いた画面を見せる → スクロールして全文表示 → きろくタブへ"
)

do_ipad=false
convert_only=false

for arg in "$@"; do
  case "$arg" in
    --ipad) do_ipad=true ;;
    --convert) convert_only=true ;;
  esac
done

# --- 録画関数 ---
record_one() {
  local device_id="$1"
  local slug="$2"
  local desc="$3"
  local out_file="$RAW_DIR/${slug}.mov"

  echo ""
  echo "====================================="
  echo "  録画: $slug"
  echo "  操作: $desc"
  echo "====================================="
  echo ""
  echo "  シミュレータでアプリを準備してください。"
  echo "  準備できたら Enter を押すと録画開始します。"
  read -r

  echo "  録画中... 操作してください。終わったら Enter で停止。"
  xcrun simctl io "$device_id" recordVideo --codec=h264 "$out_file" &
  local pid=$!

  read -r
  kill -INT "$pid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true

  echo "  保存: $out_file"
}

# --- 変換関数（Apple 要件に合わせる）---
convert_one() {
  local input="$1"
  local output="$2"
  local size="$3"

  echo "  変換: $(basename "$input") → $(basename "$output")"
  ffmpeg -y -i "$input" \
    -f lavfi -i "anullsrc=channel_layout=stereo:sample_rate=44100" \
    -r "$FPS" \
    -vf "scale=${size}:force_original_aspect_ratio=decrease,pad=${size}:(ow-iw)/2:(oh-ih)/2,format=yuv420p" \
    -c:v libx264 -profile:v high -pix_fmt yuv420p \
    -c:a aac -b:a 128k \
    -shortest -t 30 \
    -movflags +faststart \
    "$output" 2>/dev/null
}

# --- メイン ---

if ! $convert_only; then
  # iPhone 録画
  IPHONE_ID=$(xcrun simctl list devices booted | grep -i "iPhone" | head -1 | grep -oE '[0-9A-F-]{36}')
  if [[ -z "$IPHONE_ID" ]]; then
    echo "起動中の iPhone シミュレータが見つかりません。"
    echo "  xcrun simctl boot <device-id>"
    exit 1
  fi
  echo "iPhone シミュレータ: $IPHONE_ID"

  for theme in "${THEMES[@]}"; do
    slug="${theme%%|*}"
    desc="${theme#*|}"
    record_one "$IPHONE_ID" "${slug}_iphone" "$desc"
  done

  # iPad 録画
  if $do_ipad; then
    IPAD_ID=$(xcrun simctl list devices booted | grep -i "iPad" | head -1 | grep -oE '[0-9A-F-]{36}')
    if [[ -z "$IPAD_ID" ]]; then
      echo "起動中の iPad シミュレータが見つかりません。"
      echo "  xcrun simctl boot <device-id>"
      exit 1
    fi
    echo ""
    echo "iPad シミュレータ: $IPAD_ID"
    for theme in "${THEMES[@]}"; do
      slug="${theme%%|*}"
      desc="${theme#*|}"
      record_one "$IPAD_ID" "${slug}_ipad" "$desc"
    done
  fi
fi

# --- 変換 ---
echo ""
echo "===== Apple 要件に変換中 ====="

for theme in "${THEMES[@]}"; do
  slug="${theme%%|*}"
  raw_iphone="$RAW_DIR/${slug}_iphone.mov"
  if [[ -f "$raw_iphone" ]]; then
    convert_one "$raw_iphone" "$OUT_DIR/${slug}_IPHONE_65.mp4" "$IPHONE_SIZE"
    cp "$OUT_DIR/${slug}_IPHONE_65.mp4" "$OUT_DIR/${slug}_IPHONE_67.mp4"
    cp "$OUT_DIR/${slug}_IPHONE_65.mp4" "$DELIVER_DIR/${slug}_IPHONE_65.mp4"
    cp "$OUT_DIR/${slug}_IPHONE_67.mp4" "$DELIVER_DIR/${slug}_IPHONE_67.mp4"
  fi

  raw_ipad="$RAW_DIR/${slug}_ipad.mov"
  if [[ -f "$raw_ipad" ]]; then
    convert_one "$raw_ipad" "$OUT_DIR/${slug}_IPAD_PRO_3GEN_129.mp4" "$IPAD_SIZE"
    cp "$OUT_DIR/${slug}_IPAD_PRO_3GEN_129.mp4" "$DELIVER_DIR/${slug}_IPAD_PRO_3GEN_129.mp4"
  elif [[ -f "$raw_iphone" ]]; then
    echo "  iPad録画なし → iPhone録画をiPadサイズに変換"
    convert_one "$raw_iphone" "$OUT_DIR/${slug}_IPAD_PRO_3GEN_129.mp4" "$IPAD_SIZE"
    cp "$OUT_DIR/${slug}_IPAD_PRO_3GEN_129.mp4" "$DELIVER_DIR/${slug}_IPAD_PRO_3GEN_129.mp4"
  fi
done

echo ""
echo "===== 検証 ====="
for f in "$OUT_DIR"/*.mp4; do
  fps=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of csv=p=0 "$f")
  dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$f")
  res=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$f")
  audio=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of csv=p=0 "$f")
  echo "  $(basename "$f"): ${res} ${fps}fps ${dur}s audio=${audio}"
done

echo ""
echo "完了！次のステップ:"
echo "  bundle exec fastlane upload_all"
echo ""
