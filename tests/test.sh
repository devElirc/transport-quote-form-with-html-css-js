#!/bin/bash
set -euo pipefail

SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
TEST_DIR="${TEST_DIR:-$(cd "$(dirname "$SCRIPT_PATH")" && pwd)}"

export PLAYWRIGHT_BROWSERS_PATH="${PLAYWRIGHT_BROWSERS_PATH:-/ms-playwright}"

mkdir -p /logs/verifier

TEST_EXIT=0

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
  "calculateQuote"
  "baseFee"
  "mileageRate"
  "routeDistances"
  "Estimated transport quote"
  "Please select a valid year, make, and model"
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
# Behavior smoke checks (so key requirements aren't "hidden" in JS specs)
# --------------------------------------------------------------------------------------
if [ "$TEST_EXIT" -eq 0 ]; then
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

  // Step gating / ARIA: Vehicle starts disabled; clicking with valid inputs unlocks it and selects it.
  const vehicleTab = page.getByRole("tab", { name: /vehicle/i });
  if (await vehicleTab.isEnabled()) throw new Error("Expected Vehicle tab to start disabled.");

  await page.getByRole("textbox", { name: "Pickup" }).fill("Los Angeles");
  await page.getByRole("textbox", { name: "Delivery" }).fill("Houston");
  await page.getByRole("button", { name: "VEHICLE DETAILS" }).click();
  await page.waitForTimeout(250);
  if (!(await vehicleTab.isEnabled())) throw new Error("Expected Vehicle tab to be enabled after Step 1 completion.");
  const selected = await vehicleTab.getAttribute("aria-selected");
  if (selected !== "true") throw new Error("Expected Vehicle tab aria-selected=true after navigation.");

  // Validation copy: clicking calculate with missing fields should show the error text (not just exist hidden).
  await page.getByRole("button", { name: "SAVE Calculate Cost" }).click();
  const validation = page.getByText(/Please select a valid year, make, and model\.?/);
  if (!(await validation.isVisible())) throw new Error("Expected vehicle validation message to be visible.");

  // Quote calculation: a filled-out happy path renders the quote heading.
  const currentYear = new Date().getFullYear();
  await page.getByRole("combobox", { name: "Vehicle Year" }).fill(String(currentYear - 2));
  await page.getByRole("combobox", { name: "Vehicle Make" }).selectOption("Toyota");
  await page.getByRole("combobox", { name: "Vehicle Model" }).selectOption("Camry");
  await page.getByRole("button", { name: "SAVE Calculate Cost" }).click();
  const heading = page.getByRole("heading", { name: "Estimated transport quote" });
  if (!(await heading.isVisible())) throw new Error("Expected quote heading to be visible after valid calculation.");

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
  if [ $? -ne 0 ]; then
    TEST_EXIT=1
  fi
fi

# --------------------------------------------------------------------------------------
# Run the behavioral test suite (Vitest contract + Playwright E2E)
# --------------------------------------------------------------------------------------
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