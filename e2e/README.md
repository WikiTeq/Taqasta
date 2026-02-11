# Taqasta E2E Tests

End-to-end tests for the Taqasta MediaWiki stack using [Playwright](https://playwright.dev/).

## What's tested

- **001-base.spec.ts** — Installation message, login/signup links, Vector skin, anonymous edit, VisualEditor, Special:Version
- **002-edit.spec.ts** — Editing pages
- **003-upload.spec.ts** — File uploads
- **004-admin.spec.ts** — Admin/special page behavior
- **005-createaccount.spec.ts** — Account creation

## Prerequisites

- Node.js (see root `package.json` or use the version used by the project)
- A running Taqasta instance (e.g. via `docker compose up` from the repo root)

## Running locally

1. From the **Taqasta repo root**, start the stack so the wiki is available (e.g. at `http://localhost:8000`).
2. From the **e2e** directory:

   ```bash
   cd e2e
   npm install
   npx playwright test
   ```

By default the tests use `baseURL = http://localhost:8000` (see `playwright.config.ts`).

## Running in Docker / CI

Set `TAQASTA_E2E_IN_DOCKER=1` so that:

- `baseURL` is `http://web:80/` (wiki container hostname).
- The HTML reporter runs with `open: 'never'` (no browser popup).

Run the tests inside the same Docker network as the Taqasta `web` service (e.g. from a CI job or a container that has network access to `web`).

## Configuration

- **playwright.config.ts** — Base URL, timeouts, single worker (tests are sequential), Chromium only.
- **LocalSettings.php** — Minimal MediaWiki config used when running the wiki for E2E (e.g. in a dedicated test container).
- **fixtures/** — Test assets (e.g. images) for upload tests.

## Viewing results

- Failed runs keep traces and screenshots (see Playwright docs).
- With the default reporter, an HTML report is generated; use `npx playwright show-report` to open it after a run.
