## Test Suite

This task is verified with **Vitest** (static `/app/index.html`), **Playwright** (`tests/e2e/`), a small **Python** module (`tests/test_outputs.py`), and **lightweight grep checks** in `tests/test.sh` (required literals, document title, `role=tablist`) before `npm test`. Browser behavior is **not** duplicated in `test.sh`; it lives only in the E2E spec.

### Behavior coverage (where each requirement is tested)

| Requirement | Vitest `unit/` | Playwright `e2e/` | `test.sh` grep (strings / markup) |
| --- | --- | --- | --- |
| Same-city pickup/delivery after normalization | message substring in HTML | `rejects same-city pickup and delivery` | same-city message literal |
| Step 1 blank / whitespace-only | copy in HTML | `validates blank…` / `whitespace-only…` | step-1 message literal |
| Step 2 validation + `Success!` | copy in HTML | `shows validation…` | validation + `Success!` literals |
| Year datalist 1980 → current year | `list=` + loop substring | `load dependent models` (count + bounds) | year loop substring |
| Model disabled / `Select model` / dependent make→model | regex on static HTML | `load dependent models` / `clearing the vehicle make…` | `populateModels`, Toyota models |
| Out-of-range years, tamper, etc. | — | dedicated e2e tests | — |

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
