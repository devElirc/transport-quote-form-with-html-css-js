## Test suite

This task is verified with **both unit and E2E tests**:

- **Unit (Vitest)**: `tests/unit/transport-quote-form.spec.ts`
  - Enforces required literal substrings and markup contracts (title, ARIA labels, exact error strings, `populateModels`, the year loop text, quote-calculation tokens).
- **E2E (Playwright)**: `tests/e2e/transport-quote-form.spec.ts`
  - Drives the UI end-to-end (step locking, validation, dependent make/model dropdown, year datalist range, quote panel output).

`tests/test.sh` installs dependencies in the `tests/` harness directory and runs:

```bash
npm run test
```

which executes `test:unit` then `test:e2e` (see `tests/package.json`).
# UI task test suite

This task uses **Vitest** for fast markup/DOM contract checks and **Playwright** for browser-level interaction checks. Dependencies are installed at verifier time via `tests/test.sh`.

**This task:** The agent implements the static page at `/app/index.html`. Playwright serves `/app` via `npx serve`, and Vitest reads `/app/index.html` for markup contract checks.

## Layout

- **`unit/`** — Vitest specs (`*.spec.ts`) that validate important substrings/markup in `/app/index.html`.
- **`e2e/`** — Playwright specs. The dev server is started via `webServer` in `playwright.config.ts` (static hosting of `/app`).

## Commands

```bash
npm run test       # Unit tests (Vitest)
npm run test:e2e    # E2E tests (Playwright; starts webServer automatically)
```

## E2E and your app

In `playwright.config.ts`, `webServer` is configured to statically serve `/app` on port 3000.
