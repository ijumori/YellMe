#!/usr/bin/env bash
# 新ビルド: Archive → IPA → ASC アップロード（審査提出は別: fastlane submit_review）
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
export PATH="/opt/homebrew/opt/ruby/bin:${PATH:-}"

DO_SUBMIT=false
for a in "$@"; do
  case "$a" in
    --submit) DO_SUBMIT=true ;;
  esac
done

echo "==> ビルド番号確認（project.yml / Info.plist = 7 想定）"
grep -E "CURRENT_PROJECT_VERSION|CFBundleVersion" "$ROOT/project.yml" "$ROOT/Sources/Info.plist" | head -5

"$ROOT/scripts/archive-export-appstore.sh"

if [[ -n "${ASC_API_KEY_ID:-}" && -n "${ASC_API_ISSUER_ID:-}" && -n "${ASC_API_KEY_PATH:-}" ]]; then
  echo "==> API キーでアップロード"
  "$ROOT/scripts/archive-export-appstore.sh" --upload
else
  echo "==> Apple ID（fastlane）でアップロード"
  bundle exec fastlane upload_build
fi

echo ""
echo "✅ ビルドアップロード完了"
echo "   App Store Connect → TestFlight で処理が終わるまで 10〜30 分待ってください。"
echo "   その後、審査提出:"
echo "     bundle exec fastlane submit_review"
echo "   または ASC Web でビルド 7 を選んで「審査に提出」"

if $DO_SUBMIT; then
  echo ""
  echo "⚠️  --submit: ビルド処理が終わっていないと失敗します。通常は処理後に submit_review を実行してください。"
  bundle exec fastlane submit_review || true
fi
