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
