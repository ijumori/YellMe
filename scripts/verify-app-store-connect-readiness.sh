#!/usr/bin/env bash
# App Store Connect 提出前の「ローカルで機械的に確認できる項目」を検証する。
# 契約・銀行・税務・IAP の ASC 画面上の状態は別途人手で確認する。
# メタデータ／スクショの自動反映は scripts/upload-app-store-connect.sh を参照。
# 検証後に手動チェックリストを表示する。
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

FAILURES=0
err() { echo "❌ $*" >&2; FAILURES=$((FAILURES + 1)); }
ok()  { echo "✅ $*"; }

INFO_PLIST="${ROOT}/Sources/Info.plist"
PROJECT_YML="${ROOT}/project.yml"

usage() {
  sed -n '1,20p' "$0" | tail -n +2
  echo "Usage: $0 [--build] [--open]"
  echo "  --build  xcodegen generate のうえ xcodebuild（署名なし）でコンパイル確認"
  echo "  --open    ブラウザで App Store Connect / 税務ヘルプを開く（macOS）"
}

DO_BUILD=false
DO_OPEN=false
for a in "$@"; do
  case "$a" in
    -h|--help) usage; exit 0 ;;
    --build) DO_BUILD=true ;;
    --open) DO_OPEN=true ;;
    *) echo "Unknown option: $a" >&2; usage; exit 2 ;;
  esac
done

if [[ ! -f "$INFO_PLIST" ]]; then err "Sources/Info.plist が見つかりません"; fi
if [[ ! -f "$PROJECT_YML" ]]; then err "project.yml が見つかりません"; fi
if [[ $FAILURES -gt 0 ]]; then exit 1; fi

plist_get() {
  /usr/libexec/PlistBuddy -c "Print :$1" "$INFO_PLIST" 2>/dev/null || true
}

BUNDLE_SHORT="$(plist_get CFBundleShortVersionString)"
BUNDLE_BUILD="$(plist_get CFBundleVersion)"
PRODUCT_ID="$(plist_get YELLME_PREMIUM_PRODUCT_ID)"
DISPLAY_NAME="$(plist_get CFBundleDisplayName)"

if [[ -z "$PRODUCT_ID" ]]; then
  err "Info.plist に YELLME_PREMIUM_PRODUCT_ID がありません"
else
  ok "YELLME_PREMIUM_PRODUCT_ID = ${PRODUCT_ID}"
fi

if [[ "$PRODUCT_ID" != "com.takahiro.yellme.premium.monthly" ]]; then
  echo "⚠️  期待 ID（リポジトリ標準）: com.takahiro.yellme.premium.monthly — ASC のサブスク ID と一致させてください" >&2
fi

if ! grep -q "YELLME_PREMIUM_PRODUCT_ID: ${PRODUCT_ID}" "$PROJECT_YML" 2>/dev/null; then
  err "project.yml の YELLME_PREMIUM_PRODUCT_ID が Info.plist と一致しません"
else
  ok "project.yml の YELLME_PREMIUM_PRODUCT_ID が Info.plist と一致"
fi

# project.yml（settings.base）の MARKETING_VERSION / CURRENT_PROJECT_VERSION
YML_MARKETING="$(awk '/^settings:/{s=0} /^  base:/{s=1} s && /^    MARKETING_VERSION:/{print $2; exit}' "$PROJECT_YML" | tr -d '"' )"
YML_BUILD="$(awk '/^settings:/{s=0} /^  base:/{s=1} s && /^    CURRENT_PROJECT_VERSION:/{print $2; exit}' "$PROJECT_YML" | tr -d '"' )"

if [[ -n "$YML_MARKETING" && "$BUNDLE_SHORT" != "$YML_MARKETING" ]]; then
  err "MARKETING_VERSION (${YML_MARKETING}) と CFBundleShortVersionString (${BUNDLE_SHORT}) が不一致"
else
  ok "マーケティングバージョン整合: ${BUNDLE_SHORT}"
fi

if [[ -n "$YML_BUILD" && "$BUNDLE_BUILD" != "$YML_BUILD" ]]; then
  err "CURRENT_PROJECT_VERSION (${YML_BUILD}) と CFBundleVersion (${BUNDLE_BUILD}) が不一致（xcodegen generate を実行しましたか）"
else
  ok "ビルド番号整合: ${BUNDLE_BUILD}"
fi

if ! grep -q 'PRODUCT_BUNDLE_IDENTIFIER: com.takahiro.yellme' "$PROJECT_YML"; then
  err "project.yml に PRODUCT_BUNDLE_IDENTIFIER: com.takahiro.yellme がありません"
else
  ok "Bundle ID = com.takahiro.yellme（project.yml）"
fi

if ! grep -q 'DEVELOPMENT_TEAM:' "$PROJECT_YML" || grep -q 'DEVELOPMENT_TEAM:[[:space:]]*$' "$PROJECT_YML"; then
  err "DEVELOPMENT_TEAM が空の行の可能性があります（grep で要確認）"
else
  TEAM="$(grep 'DEVELOPMENT_TEAM:' "$PROJECT_YML" | tail -1 | awk '{print $2}')"
  if [[ -z "$TEAM" || "$TEAM" == '""' ]]; then
    err "DEVELOPMENT_TEAM が未設定です"
  else
    ok "DEVELOPMENT_TEAM = ${TEAM}"
  fi
fi

if ! grep -q 'ITSAppUsesNonExemptEncryption' "$INFO_PLIST"; then
  err "ITSAppUsesNonExemptEncryption が Info.plist にありません（輸出コンプライアンス）"
else
  ok "ITSAppUsesNonExemptEncryption が Info.plist に存在"
fi

if [[ -n "$DISPLAY_NAME" ]]; then
  ok "CFBundleDisplayName = ${DISPLAY_NAME}"
fi

if $DO_BUILD; then
  echo ""
  echo "—— xcodegen + xcodebuild ——"
  if ! command -v xcodegen &>/dev/null; then
    err "xcodegen が PATH にありません"
  else
    xcodegen generate
    if xcodebuild -project YellMe.xcodeproj -scheme YellMe -destination 'generic/platform=iOS' -configuration Debug build CODE_SIGNING_ALLOWED=NO -quiet; then
      ok "xcodebuild（generic iOS, 署名なし）成功"
    else
      err "xcodebuild が失敗しました"
    fi
  fi
fi

if $DO_OPEN && [[ "$(uname)" == "Darwin" ]]; then
  echo ""
  echo "—— ブラウザを開きます ——"
  open "https://appstoreconnect.apple.com/" || true
  open "https://developer.apple.com/jp/help/app-store-connect/manage-tax-information/provide-tax-information/" || true
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "【手動】App Store Connect で優先度順に必ず確認すること"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " 1. ビジネス → 契約、税務、銀行業務"
echo "    · 有料 App 利用規約が「有効」"
echo "    · 銀行口座・税務（W-8BEN 等）が完了・送信済み"
echo ""
echo " 2. アプリ「エールミー」→ 機能 → App 内課金"
echo "    · サブスク ID が次と完全一致: ${PRODUCT_ID}"
echo "    · メタデータ不足で止まっていない（審査用情報・ローカライズ等）"
echo "    · 提出するバージョンに IAP が関連付けされている"
echo ""
echo " 3. developer.apple.com → Identifiers → App ID com.takahiro.yellme"
echo "    · In-App Purchase が有効（必要なら）"
echo ""
echo " 4. TestFlight / 実機（Sandbox）"
echo "    · マイページ → Premium で Product.products が成功し購入フローまで通る"
echo ""
echo " 5. 審査情報"
echo "    · デモ手順・連絡先・プライバシー URL 等が最新"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ $FAILURES -gt 0 ]]; then
  echo "" >&2
  echo "検証失敗: ${FAILURES} 件" >&2
  exit 1
fi

echo ""
echo "ローカル自動検証はすべて通過しました（上記手動項目は別途 ASC で確認してください）。"
