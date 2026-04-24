#!/bin/bash
set -euo pipefail

SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
TEST_DIR="${TEST_DIR:-$(cd "$(dirname "$SCRIPT_PATH")" && pwd)}"

export PLAYWRIGHT_BROWSERS_PATH="${PLAYWRIGHT_BROWSERS_PATH:-/ms-playwright}"

mkdir -p /logs/verifier

TEST_EXIT=0

# --------------------------------------------------------------------------------------
# Coverage map (instruction ↔ tests)
# --------------------------------------------------------------------------------------
# - Static HTML contract: tests/unit/transport-quote-form.spec.ts
# - Browser behavior: tests/e2e/transport-quote-form.spec.ts
# - Pytest harness smoke: tests/test_outputs.py
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
    echo "Error: python3 is required to run tests/test_outputs.py (pytest)." >&2
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
    echo "Error: tests/test_outputs.py is missing (pytest harness smoke tests)." >&2
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
# Run the behavioral test suite (Vitest + Playwright + Pytest harness smoke)
# --------------------------------------------------------------------------------------
set +e
SUITE_OK=0
if [ "$TEST_EXIT" -eq 0 ]; then
  npm run test
  NPM_STATUS=$?
  # Pytest is a Python package (not npm). Pin it for reproducible harness audits.
  # Prefer a project-local venv: many distros ship PEP 668 "externally managed" Python
  # where global/user pip installs are refused (both attempts would fail silently).
  PY_STATUS=0
  VENV_DIR="${TEST_DIR}/.pytest-venv"
  USE_VENV=0
  if [ -x "${VENV_DIR}/bin/python" ]; then
    USE_VENV=1
  elif python3 -m venv "${VENV_DIR}" >/dev/null 2>&1; then
    USE_VENV=1
  fi
  if [ "$USE_VENV" -eq 1 ]; then
    if ! "${VENV_DIR}/bin/pip" install --disable-pip-version-check --no-input \
      pytest==8.3.4 >/dev/null 2>&1; then
      echo "Error: could not install pinned pytest==8.3.4 into ${VENV_DIR}." >&2
      PY_STATUS=1
    fi
  else
    if python3 -m pip install --disable-pip-version-check --no-input \
      --root-user-action=ignore pytest==8.3.4 >/dev/null 2>&1; then
      :
    elif python3 -m pip install --disable-pip-version-check --no-input \
      --user pytest==8.3.4 >/dev/null 2>&1; then
      :
    elif python3 -m pip install --disable-pip-version-check --no-input \
      --break-system-packages pytest==8.3.4 >/dev/null 2>&1; then
      :
    else
      echo "Error: could not install pinned pytest==8.3.4 for test_outputs.py (venv creation also failed)." >&2
      PY_STATUS=1
    fi
  fi
  if [ "${PY_STATUS:-0}" -eq 0 ]; then
    if [ "$USE_VENV" -eq 1 ]; then
      "${VENV_DIR}/bin/python" -m pytest test_outputs.py -rA
    else
      python3 -m pytest test_outputs.py -rA
    fi
    PY_STATUS=$?
  fi
  if [ "$NPM_STATUS" -eq 0 ] && [ "$PY_STATUS" -eq 0 ]; then
    SUITE_OK=1
  fi
else
  false
fi
if [ "$SUITE_OK" -eq 1 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi