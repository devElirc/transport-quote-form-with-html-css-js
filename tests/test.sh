#!/bin/bash
set -euo pipefail

SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
TEST_DIR="${TEST_DIR:-$(cd "$(dirname "$SCRIPT_PATH")" && pwd)}"

export PLAYWRIGHT_BROWSERS_PATH="${PLAYWRIGHT_BROWSERS_PATH:-/ms-playwright}"

mkdir -p /logs/verifier

run_verifier() {
TEST_EXIT=0

# --------------------------------------------------------------------------------------
# Coverage map (instruction ↔ tests)
# --------------------------------------------------------------------------------------
# Grep blocks below pin required literals/markup before npm test. Behavioral coverage is in:
#   - tests/unit/transport-quote-form.spec.ts  (static /app/index.html contract)
#   - tests/e2e/transport-quote-form.spec.ts    (Playwright)
#   - tests/test_outputs.py                      (stdlib checks on shipped HTML + lockfiles)

# --------------------------------------------------------------------------------------
# Preconditions: working dir, app artifact, and local JS test harness
# --------------------------------------------------------------------------------------
if [ "$PWD" = "/" ]; then
  echo "Error: No working directory set." >&2
  TEST_EXIT=1
fi

if [ ! -f /app/index.html ]; then
  echo "Error: /app/index.html not found." >&2
  TEST_EXIT=1
else
  cd "$TEST_DIR"
  if ! command -v python3 >/dev/null 2>&1; then
    echo "Error: python3 is required to run tests/test_outputs.py (stdlib unittest)." >&2
    TEST_EXIT=1
  fi
  if [ ! -f package.json ] || [ ! -f package-lock.json ]; then
    echo "Error: tests/package.json and tests/package-lock.json must exist for pinned deps." >&2
    TEST_EXIT=1
  fi
  if [ ! -d unit ] || [ ! -d e2e ]; then
    echo "Error: tests/unit and tests/e2e must exist." >&2
    TEST_EXIT=1
  fi
  if ! ls unit/*.spec.ts >/dev/null 2>&1 || ! ls e2e/*.spec.ts >/dev/null 2>&1; then
    echo "Error: expected Vitest + Playwright spec files under tests/unit and tests/e2e." >&2
    TEST_EXIT=1
  fi
  if [ ! -f test_outputs.py ]; then
    echo "Error: tests/test_outputs.py is missing (Python harness smoke tests)." >&2
    TEST_EXIT=1
  fi

  # Use the lockfile for reproducible installs.
  npm ci --no-fund --no-audit || TEST_EXIT=$?
fi

# --------------------------------------------------------------------------------------
# Fast-fail: required instruction-mandated literal substrings in /app/index.html
# --------------------------------------------------------------------------------------
required_literals=(
  "Toyota"
  "Camry"
  "Corolla"
  "RAV4"
  "Tacoma"
  "populateModels"
  "Please select a valid year, make, and model"
  "Success!"
  "Pickup and delivery must be different locations"
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

# --------------------------------------------------------------------------------------
# Fast markup checks (title + tab landmark; complements unit tests)
# --------------------------------------------------------------------------------------
if [ "$TEST_EXIT" -eq 0 ]; then
  if ! grep -Fq "<title>Transport Quote Form</title>" /app/index.html; then
    echo "Error: /app/index.html must include exact title <title>Transport Quote Form</title>" >&2
    TEST_EXIT=1
  fi
fi
if [ "$TEST_EXIT" -eq 0 ]; then
  if ! grep -Fq 'role="tablist"' /app/index.html && ! grep -Fq "role='tablist'" /app/index.html; then
    echo "Error: /app/index.html must include role=tablist on the step bar wrapper." >&2
    TEST_EXIT=1
  fi
fi

# --------------------------------------------------------------------------------------
# Run the behavioral test suite (Vitest + Playwright + Python harness checks)
# --------------------------------------------------------------------------------------
set +e
if [ "$TEST_EXIT" -eq 0 ]; then
  npm run test
  NPM_STATUS=$?
  # test_outputs.py uses stdlib unittest only (no pip/pytest/venv on minimal images).
  python3 -m unittest test_outputs -v
  PY_STATUS=$?
  if [ "$NPM_STATUS" -eq 0 ] && [ "$PY_STATUS" -eq 0 ]; then
    return 0
  fi
  return 1
fi
return 1
}

set +e
run_verifier
if [ $? -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi