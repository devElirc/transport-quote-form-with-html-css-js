#!/bin/bash
set -euo pipefail

SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
TEST_DIR="${TEST_DIR:-$(cd "$(dirname "$SCRIPT_PATH")" && pwd)}"

export PLAYWRIGHT_BROWSERS_PATH="${PLAYWRIGHT_BROWSERS_PATH:-/ms-playwright}"

mkdir -p /logs/verifier

TEST_EXIT=0

if [ "$PWD" = "/" ]; then
  echo "Error: No working directory set." >&2
  TEST_EXIT=1
fi

if [ ! -f /app/index.html ]; then
  echo "Error: /app/index.html not found." >&2
  TEST_EXIT=1
else
  cd "$TEST_DIR"
  npm install --no-fund --no-audit || TEST_EXIT=$?
fi

required_literals=(
  "Toyota"
  "Camry"
  "Corolla"
  "RAV4"
  "Tacoma"
  "populateModels"
  "calculateQuote"
  "baseFee"
  "mileageRate"
  "routeDistances"
  "for (let year = currentYear; year >= 1980; year -= 1)"
)

if [ "$TEST_EXIT" -eq 0 ]; then
  for literal in "${required_literals[@]}"; do
    if ! grep -Fq "$literal" /app/index.html; then
      echo "Error: /app/index.html is missing required literal: $literal" >&2
      TEST_EXIT=1
      break
    fi
  done
fi

set +e
if [ "$TEST_EXIT" -eq 0 ]; then
  npm run test
else
  false
fi
if [ $? -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
