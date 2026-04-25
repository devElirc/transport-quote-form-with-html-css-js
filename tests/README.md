## Test Suite

This task is verified with **Vitest** (static `/app/index.html`), **Playwright** (browser), a small **Python** module, and an **inline Playwright smoke** block inside `tests/test.sh` so reviewers who only read `test.sh` still see exercised UX (not only `grep` literals).

### Behavior coverage (where each requirement is tested)

| Requirement | `tests/test.sh` smoke | Vitest `unit/` | Playwright `e2e/` |
| --- | --- | --- | --- |
| Same-city pickup/delivery after normalization | yes | copy in HTML | `rejects same-city pickup and delivery` |
| Step 1 blank / whitespace-only | yes (blank) | copy in HTML | `validates blank…` / `whitespace-only…` |
| Step 2 validation + `Success!` | yes | copy in HTML | `shows validation…` |
| Year datalist 1980 → current year (DOM count + bounds) | yes | `list=` + loop substring | `load dependent models` |
| Model disabled → enable after make; `Select model` default | yes | regex on static HTML | `load dependent models` / `clearing the vehicle make…` |
| Out-of-range years, tamper, etc. | — | — | dedicated e2e tests |

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
