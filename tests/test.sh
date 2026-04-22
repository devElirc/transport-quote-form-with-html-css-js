#!/bin/bash
set -uo pipefail

TEST_DIR="${TEST_DIR:-/tests}"
REWARD_FILE="/logs/verifier/reward.txt"

mkdir -p /logs/verifier

# Verifier entrypoint (Harbor runs this script).
#
# Behavioral verification is implemented as:
# - Vitest unit tests: /tests/unit/transport-quote-form.spec.ts
# - Playwright E2E tests: /tests/e2e/transport-quote-form.spec.ts
#
# This script orchestrates installs and runs `npm run test` from /tests.

write_reward() {
  local code="$1"
  if [ "$code" -eq 0 ]; then
    echo 1 > "$REWARD_FILE"
  else
    echo 0 > "$REWARD_FILE"
  fi
}

EXIT_CODE=0

if [ "$PWD" = "/" ]; then
  echo "Error: No working directory set. Please set a WORKDIR in your Dockerfile before running this script." >&2
  write_reward 0
  exit 1
fi

# ---------------------------------------------------------------------------
# 1) Agent app contract (/app)
# ---------------------------------------------------------------------------
if [ ! -f /app/index.html ]; then
  echo "Error: /app/index.html not found." >&2
  write_reward 0
  exit 1
fi

# ---------------------------------------------------------------------------
# 2) Verifier test harness (/tests)
# ---------------------------------------------------------------------------
if [ "$EXIT_CODE" -eq 0 ]; then
  cd "$TEST_DIR"
  npm install --no-fund --no-audit || EXIT_CODE=$?
fi

if [ "$EXIT_CODE" -eq 0 ]; then
  npm run test || EXIT_CODE=$?
fi

write_reward "$EXIT_CODE"
exit "$EXIT_CODE"
