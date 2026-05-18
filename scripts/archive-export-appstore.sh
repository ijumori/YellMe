#!/usr/bin/env bash
# App Store 提出用: Archive → IPA エクスポートまでを一括実行する。
# アップロードは (1) 環境変数で API キーがあれば altool、(2) なければ Transporter 手動、のどちらか。
#
# 前提:
#   - Xcode が入り、同じ Apple Developer チームで「Automatically manage signing」が通ること
#   - リポジトリルートで実行するか、どこからでもこのスクリプトのパスで実行可
#
# 使い方:
#   ./scripts/archive-export-appstore.sh
#   ./scripts/archive-export-appstore.sh --upload   # ASC_API_* が揃っているときのみ意味あり
#
# オプションのアップロード（App Store Connect API キー）:
#   export ASC_API_KEY_ID="XXXXXXXXXX"           # キー ID（10桁）
#   export ASC_API_ISSUER_ID="uuid-issuer"       # Issuer ID（UUID）
#   export ASC_API_KEY_PATH="$HOME/AuthKey_XXX.p8"  # ダウンロードした .p8 の絶対パス
#   ./scripts/archive-export-appstore.sh --upload
#
# API キー作成: App Store Connect → ユーザーとアクセス → キー → App Store Connect API
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

DO_UPLOAD=false
for a in "$@"; do
  case "$a" in
    --upload) DO_UPLOAD=true ;;
    -h|--help)
      sed -n '1,35p' "$0" | tail -n +2
      exit 0
      ;;
  esac
done

ARCHIVE_PATH="${ROOT}/build/YellMe.xcarchive"
EXPORT_DIR="${ROOT}/build/AppStoreExport"
DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM:-NXFZ5AUX62}"
EXPORT_PLIST="${ROOT}/scripts/ExportOptions-appstore.plist"

echo "==> 1/4 xcodegen generate"
command -v xcodegen >/dev/null 2>&1 || { echo "xcodegen をインストールしてください: brew install xcodegen" >&2; exit 1; }
xcodegen generate

echo "==> 2/4 xcodebuild archive (Release, generic/iOS, チーム: ${DEVELOPMENT_TEAM})"
mkdir -p "${ROOT}/build"
rm -rf "${ARCHIVE_PATH}"

xcodebuild \
  -project "${ROOT}/YellMe.xcodeproj" \
  -scheme YellMe \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "${ARCHIVE_PATH}" \
  -allowProvisioningUpdates \
  archive \
  DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM}" \
  CODE_SIGN_STYLE=Automatic

echo "==> 3/4 xcodebuild -exportArchive → IPA"
rm -rf "${EXPORT_DIR}"
mkdir -p "${EXPORT_DIR}"

xcodebuild \
  -exportArchive \
  -archivePath "${ARCHIVE_PATH}" \
  -exportPath "${EXPORT_DIR}" \
  -exportOptionsPlist "${EXPORT_PLIST}"

IPA=$(ls -1 "${EXPORT_DIR}"/*.ipa 2>/dev/null | head -1 || true)
if [[ -z "${IPA}" ]]; then
  echo "❌ IPA が見つかりません: ${EXPORT_DIR}" >&2
  exit 1
fi

echo ""
echo "✅ IPA を作成しました:"
echo "   ${IPA}"
echo ""

if $DO_UPLOAD; then
  if [[ -z "${ASC_API_KEY_ID:-}" || -z "${ASC_API_ISSUER_ID:-}" || -z "${ASC_API_KEY_PATH:-}" ]]; then
    echo "❌ --upload には ASC_API_KEY_ID, ASC_API_ISSUER_ID, ASC_API_KEY_PATH の3つが必要です。" >&2
    exit 1
  fi
  if [[ ! -f "${ASC_API_KEY_PATH}" ]]; then
    echo "❌ ASC_API_KEY_PATH がファイルとして存在しません: ${ASC_API_KEY_PATH}" >&2
    exit 1
  fi
  echo "==> 4/4 App Store Connect にアップロード（altool）"
  # Xcode に同梱。将来削除される可能性あり — 失敗時は Transporter を利用。
  xcrun altool --upload-app \
    -f "${IPA}" \
    -t ios \
    --apiKey "${ASC_API_KEY_ID}" \
    --apiIssuer "${ASC_API_ISSUER_ID}" \
    --apiKeyPath "${ASC_API_KEY_PATH}" \
    --show-progress
  echo "✅ アップロード完了の旨が表示されたら、Connect の TestFlight で処理待ちを確認してください。"
else
  echo "—— 次のどちらかでアップロード ——"
  echo "  A) Mac App Store の「Transporter」アプリを開き、上記 IPA をドラッグ＆ドロップ"
  echo "  B) 環境変数 ASC_API_* を設定して再実行:"
  echo "       ./scripts/archive-export-appstore.sh --upload"
  echo ""
fi
