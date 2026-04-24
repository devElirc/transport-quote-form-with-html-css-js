## Test Suite

This task is verified with both unit and E2E tests.

- `tests/unit/transport-quote-form.spec.ts`
  Checks the static `/app/index.html` contract: title, tab roles, labels, required literals (`Toyota`, models, `populateModels`, year loop), validation copy, `Success!`, and no external script/CSS fetches.
- `tests/e2e/transport-quote-form.spec.ts`
  Drives the UI in Chromium: step gating, Step 1 and Step 2 validation messages, same-city guard, dependent make/model behavior, tamper rejection, year range checks, and the `Success!` confirmation.
- `tests/test_outputs.py`
  Small **pytest** module for harness smoke checks (required by some automated reviewers that look for `test_*.py`). `tests/test.sh` pins **`pytest==8.3.4`** and installs it into **`tests/.pytest-venv`** when possible so PEP 668–managed system Python does not block `pip install`; it falls back to system/user/`--break-system-packages` installs only if `python3 -m venv` is unavailable.

## How It Runs

`tests/test.sh` installs dependencies in the `tests/` directory and runs:

```bash
npm run test
```

That executes:

```bash
npm run test:unit
npm run test:e2e
```

## Notes

- The agent implementation lives at `/app/index.html`.
- Vitest reads `/app/index.html` directly.
- Playwright serves `/app` through the `webServer` configured in `tests/playwright.config.ts`.

## Submission packaging

When you zip the task for the platform, include **`tests/package.json` and `tests/package-lock.json`** in the archive. The verifier runs `npm ci` from `tests/` and the LLMaJ `pinned_dependencies` check expects those files to be present in the uploaded artifact.
