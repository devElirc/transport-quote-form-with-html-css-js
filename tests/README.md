## Test Suite

This task is verified with both unit and E2E tests.

- `tests/unit/transport-quote-form.spec.ts`
  Checks the static `/app/index.html` contract, including required literals, title, ARIA labels, tab roles, the year loop text, and quote-calculation hooks.
- `tests/e2e/transport-quote-form.spec.ts`
  Drives the UI in Chromium, covering step locking, step unlock/navigation, dependent make/model behavior, validation, quote rendering, route normalization, tamper rejection, and year edge cases.

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
