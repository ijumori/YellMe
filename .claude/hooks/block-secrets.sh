#!/bin/bash
# PreToolUse hook: シークレットファイルへの書き込みをブロック
# 対象: Write / Edit ツール
# 終了コード 2 → Claude がアクションをブロック

INPUT=$(cat)

# tool_input.file_path を取得
FILE_PATH=$(echo "$INPUT" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('file_path', ''))
except:
    print('')
" 2>/dev/null)

# ブロック対象パターン
BLOCKED=(
  "Secrets.swift"
  "GoogleService-Info.plist"
  ".env"
)

for pattern in "${BLOCKED[@]}"; do
  if [[ "$FILE_PATH" == *"$pattern"* ]]; then
    echo "🚫 BLOCKED: ${FILE_PATH} はシークレットファイルです。直接編集禁止。" >&2
    echo "  → Secrets.swift は手動で編集してください。" >&2
    exit 2
  fi
done

exit 0
