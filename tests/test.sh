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

required_literals=(
  "Transport Quote Form"
  "Transport car pickup and destination"
  "Please enter both pickup and delivery locations."
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
  "Estimated transport quote"
  "Please select a valid year, make, and model."
  "for (let year = currentYear; year >= 1980; year -= 1)"
)

for literal in "${required_literals[@]}"; do
  if ! grep -Fq "$literal" /app/index.html; then
    echo "Error: /app/index.html is missing required literal: $literal" >&2
    echo 0 > /logs/verifier/reward.txt
    exit 1
  fi
done

set +e
npm run test
if [ $? -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
