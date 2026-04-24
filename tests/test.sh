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
# - Static HTML contract: tests/unit/transport-quote-form.spec.ts
# - Browser behavior: tests/e2e/transport-quote-form.spec.ts
# - Python harness smoke (stdlib unittest): tests/test_outputs.py
# - Inline smoke below: fast Playwright sanity checks visible in this file for harness reviewers.

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
# Behavior smoke checks (so key requirements aren't "hidden" in JS specs)
# --------------------------------------------------------------------------------------
if [ "$TEST_EXIT" -eq 0 ]; then
  # Never allow errexit during the smoke runner: a non-zero Node exit must not skip reward.txt.
  set +e
  node --input-type=module <<'EOF'
import { spawn } from "node:child_process";
import process from "node:process";
import { chromium } from "@playwright/test";

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function waitForServer(url, timeoutMs) {
  const started = Date.now();
  while (Date.now() - started < timeoutMs) {
    try {
      const res = await fetch(url, { method: "GET" });
      if (res.ok) return;
    } catch {
      // ignore
    }
    await sleep(200);
  }
  throw new Error(`Timed out waiting for server at ${url}`);
}

// Use a different port than the Playwright E2E suite (3000) to avoid conflicts.
const smokePort = 3100;
const smokeUrl = `http://localhost:${smokePort}`;

const server = spawn("npx", ["serve", "/app", "-p", String(smokePort)], {
  stdio: "ignore",
  env: process.env,
});

let exitCode = 0;
try {
  await waitForServer(smokeUrl, 15000);

  const browser = await chromium.launch();
  const page = await browser.newPage();
  await page.goto(smokeUrl, { waitUntil: "domcontentloaded" });

  const vehicleTab = page.getByRole("tab", { name: /vehicle/i });

  // Step 1 validation: blank locations should show the required copy and keep Vehicle locked.
  await page.getByRole("button", { name: "VEHICLE DETAILS" }).click();
  const step1Error = page.getByText(/Please enter both pickup and delivery locations\.?/);
  if (!(await step1Error.isVisible())) throw new Error("Expected Step 1 validation message to be visible.");
  if (!(await vehicleTab.isDisabled())) throw new Error("Expected Vehicle tab to stay disabled when Step 1 is invalid.");

  // Step gating / ARIA: after valid Step 1, Vehicle unlocks and becomes selected.
  await page.getByRole("textbox", { name: "Pickup" }).fill("Los Angeles");
  await page.getByRole("textbox", { name: "Delivery" }).fill("Houston");
  await page.getByRole("button", { name: "VEHICLE DETAILS" }).click();
  await page.waitForTimeout(250);
  if (!(await vehicleTab.isEnabled())) throw new Error("Expected Vehicle tab to be enabled after Step 1 completion.");
  const selected = await vehicleTab.getAttribute("aria-selected");
  if (selected !== "true") throw new Error("Expected Vehicle tab aria-selected=true after navigation.");

  // Validation: empty vehicle fields should show the required copy (optional trailing period).
  await page.getByRole("button", { name: "SAVE Calculate Cost" }).click();
  const validation = page.getByText(/Please select a valid year, make, and model\.?/);
  if (!(await validation.isVisible())) throw new Error("Expected vehicle validation message to be visible.");

  // Valid vehicle details should show the Success confirmation (instruction).
  const currentYear = new Date().getFullYear();
  const quotedYear = currentYear - 2;
  await page.getByRole("combobox", { name: "Vehicle Year" }).fill(String(quotedYear));
  await page.getByRole("combobox", { name: "Vehicle Make" }).selectOption("Toyota");
  await page.getByRole("combobox", { name: "Vehicle Model" }).selectOption("Camry");
  await page.getByRole("button", { name: "SAVE Calculate Cost" }).click();
  const success = page.getByText(/^Success!$/);
  if (!(await success.isVisible())) throw new Error("Expected Success! confirmation to be visible.");

  await browser.close();
} catch (err) {
  console.error(String(err?.stack ?? err));
  exitCode = 1;
} finally {
  try {
    server.kill("SIGTERM");
  } catch {
    // ignore
  }
  // Ensure the port is released before the E2E suite starts.
  await Promise.race([
    new Promise((resolve) => server.once("exit", resolve)),
    sleep(1500),
  ]);
  if (!server.killed) {
    try {
      server.kill("SIGKILL");
    } catch {
      // ignore
    }
  }
}

process.exit(exitCode);
EOF
  smoke_status=$?
  set -euo pipefail
  if [ "$smoke_status" -ne 0 ]; then
    TEST_EXIT=1
  fi
fi

# --------------------------------------------------------------------------------------
# Run the behavioral test suite (Vitest + Playwright + Python harness smoke)
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