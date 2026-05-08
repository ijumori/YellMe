#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${ROOT}/Sources/Core/Services/Secrets.swift"
SRC="${ROOT}/Sources/Core/Services/Secrets.swift.example"

if [[ ! -f "${SRC}" ]]; then
  echo "error: missing ${SRC}" >&2
  exit 1
fi

if [[ -f "${DEST}" ]]; then
  echo "Secrets.swift already exists — leaving unchanged."
  exit 0
fi

cp "${SRC}" "${DEST}"
echo "Created ${DEST} from example."
echo "Edit claudeAPIKey, then build. Do not commit Secrets.swift."
