## Test Suite

This task is verified with both unit and E2E tests.

- `tests/unit/transport-quote-form.spec.ts`
  Checks the static `/app/index.html` contract: title, tab roles, labels, required literals (`Toyota`, models, `populateModels`, year loop), validation copy, `Success!`, and no external script/CSS fetches.
- `tests/e2e/transport-quote-form.spec.ts`
  Drives the UI in Chromium: step gating, Step 1 and Step 2 validation messages, same-city guard, dependent make/model behavior, tamper rejection, year range checks, and the `Success!` confirmation.
- `tests/test_outputs.py`
  Small **Python** module for harness smoke checks (required by some automated reviewers that look for `test_*.py`). It uses **stdlib `unittest` only**—no `pip`, `pytest`, or `venv`—so minimal verifier images still run it via `python3 -m unittest test_outputs -v` from `tests/test.sh`.

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
