#!/bin/bash
set -euo pipefail

SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
TEST_DIR="${TEST_DIR:-$(cd "$(dirname "$SCRIPT_PATH")" && pwd)}"

export PLAYWRIGHT_BROWSERS_PATH="${PLAYWRIGHT_BROWSERS_PATH:-/ms-playwright}"

mkdir -p /logs/verifier

if [ ! -f /app/index.html ]; then
  echo "Error: /app/index.html not found." >&2
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

cd "$TEST_DIR"
if ! npm install --no-fund --no-audit; then
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

if npm run test; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi
