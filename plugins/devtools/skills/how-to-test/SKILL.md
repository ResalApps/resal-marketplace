---
name: how-to-test
description: "Use when a feature or specification implementation is complete (alongside the full-suite run and PR) and you need to produce or update an internal QA-facing How-To-Test manual for development-only use: an HTML walkthrough covering every user case, with Playwright screenshots (captured against mocked backend endpoints only) for web pages and request/response samples for headless APIs. Supports single-project and multi-project workspaces."
---

# how-to-test

Produce (or update) an internal QA-facing **How-To-Test manual** intended for development and QA
staff (not external end users). Treat it as part of "done", alongside the full-suite run and the PR.
The manual is a draft QA guide a human can follow by hand to validate every user case — not a
substitute for automated tests.

If the workspace contains multiple projects (e.g. a monorepo or multi-repo workspace), generate a
separate manual per project and a **workspace-level index** aggregating all of them.

## Workspace discovery

Before generating, scan the workspace root to detect project structure:

1. Look for `package.json`, `*.csproj`, `pyproject.toml`, `go.mod`, `Cargo.toml`, or other
   language/framework markers.
2. Identify how the app is started in development (`docker compose up`, `npm run dev`,
   `aspire run`, `dotnet run`, `uv run`, etc.).
3. For multi-project workspaces:
   - Note the project name and root path for each project.
   - If a shared `how-to-test/` directory already exists (at workspace root or one project's
     public dir), use it as the output root.
   - Otherwise, default to `<project-root>/how-to-test/` for each project.

## Security and redaction rules

The manual is for internal QA, but it must not collect or publish secrets. Never include plaintext
passwords, API keys, bearer tokens, refresh tokens, session IDs, cookies, private keys, OAuth codes,
database URLs, connection strings, or full `.env` values in generated HTML, screenshots, request
samples, logs, or comments.

When documenting prerequisites:
- List environment variable names and purpose only; use placeholders such as `<REDACTED>` or
  `<set locally>`.
- For seeded dev accounts, include non-secret identifiers such as usernames/emails only when they
  are already documented test identities. Do not include passwords; say to retrieve them from the
  approved secret store or existing team runbook.
- Redact `Authorization`, `Cookie`, `Set-Cookie`, `X-Api-Key`, OAuth, CSRF, and similar headers from
  every curl output and request/response sample.
- If an existing test fixture contains realistic-looking credentials, replace the value with
  `<REDACTED>` before writing it into the manual.

If a flow needs authentication, prefer mocked/stubbed auth responses with fake tokens. Do not capture
screenshots of pages that visibly show real secrets or personal data; mask or replace that data in
the Playwright route mocks first.

## Output conventions

Output paths depend on the project type detected. Choose the best match:

### Web frontend (Vite / Next.js / CRA)

- **Manual:** `<public-dir>/how-to-test/<feature-slug>.html` (self-contained, inline CSS).
  Use slug format `<ticket-number>-<short-name>` lowercase, hyphen-separated, ASCII only (e.g.
  `1234-plan-catalog`), max 50 chars.
- **Assets:** `<public-dir>/how-to-test/assets/*.png`.
- **Stripped from production build:** add a Vite plugin or build exclusion that strips the
  whole `how-to-test/` directory so dev credentials never ship to prod.
- **In-app link (Development only):** gate on an environment variable or build flag
  (e.g. `import.meta.env.DEV`, `NODE_ENV === 'development'`, `__DEV__`). Never linked in
  production.

### Generic (no web frontend detected)

- **Manual:** `<project-root>/how-to-test/<feature-slug>.html`.
- **Assets:** `<project-root>/how-to-test/assets/*.png`.

### Screenshots & test naming

Use filenames `<feature-slug>--<page-slug>.png` and a test file named
`<nn>-howto-<feature-slug>.spec.ts` to avoid collisions. Document naming in the manual.

### Index file

Place an `index.html` in the same directory as the manuals — a TOC with a brief description of
each feature/manual and a link to it. In a multi-project workspace, create a **workspace-level
index** at `<workspace-root>/how-to-test/index.html` that lists all projects' manuals grouped by
project, plus a per-project index inside each project's how-to-test directory.

## What the manual must contain (ordered subtasks)

Proceed in the order below — each step depends on the previous one.

1. **Scaffold HTML** — Create the file with a Cover + TOC with anchor links; mark it a
   Development-only draft. Include the full HTML document structure.
2. **Prerequisites & dev tooling** — how to start the app in development, any seeded dev
   test account identifiers, required environment variable names, dev URLs / dashboards. Apply the
   redaction rules above; do not print secrets or passwords.
3. **A diagram** of the feature's flow. Include a mermaid flow diagram embedded via CDN. If mermaid
   is not possible, include an inline SVG; use excalidraw only if both are unavailable. Provide a
   one-sentence text fallback caption.
4. **One section per user story / use case**, each a numbered step list a tester follows.
5. **Screenshots for every Form / web page** (see below) — each `<img>` must have an `alt` attribute
   and a one-line caption describing the state (e.g., "New plan modal open with default values").
   Ensure the HTML page passes an automated a11y smoke check.
6. **Request/response samples for headless API endpoints** (no UI) — derive shapes from the
   feature's API contract (e.g. `contracts/openapi.yaml`, `spec/openapi.json`, `api/*.http`);
   show method, path, intended caller (e.g., web-client, internal-service) or OAuth `aud` claim,
   and a JSON excerpt. If the API contract is missing or out-of-date, generate samples from the
   server's dev stub or integration tests and mark them with "(inferred)" including the source
   file/path used. If samples differ from the running dev server, mark the sample with "(mismatch)"
   and include the actual curl response from the dev server plus a note instructing to update the
   API contract.

### Checklist

- [ ] Cover + TOC present and marked Development-only draft
- [ ] Prerequisites section complete (dev start command, redacted test-account/env-var guidance, URLs)
- [ ] Flow diagram included (mermaid via CDN preferred)
- [ ] User story sections present with numbered step lists
- [ ] Screenshots for each form/page — each has `alt` text and caption; HTML passes a11y smoke check
- [ ] API samples derived from API contract (or marked "(inferred)"/"(mismatch)" if not)
- [ ] Index file updated (project-level and, for multi-project workspaces, workspace-level)

## Generating screenshots (do NOT hand-take them)

Add a Playwright spec that **mocks all backend endpoints the feature's UI depends on** with
`page.route(...)` and captures full-page PNGs into the assets dir — frontend-only, no backend, fast.
Do **not** mock unrelated analytics/telemetry endpoints unless they affect layout. Reuse the mock
shapes from the feature's existing render specs.

Ensure mocks provide stable, deterministic data (fixed timestamps, deterministic IDs). Document any
dynamic regions and how to normalize them (CSS masks, fixed data in mocks).

If the page requires third-party interactive auth (OAuth), mock the auth exchange or provide a
stubbed dev auth flow; include exact Playwright steps to bypass interactive popups (e.g., stub token
endpoints or use pre-authenticated state).

```ts
const ASSETS = "<assets-directory>"; // e.g. "frontend/public/how-to-test/assets"
test("capture: <page>", async ({ page }) => {
  await page.route("**/api/<endpoint>", (r) =>
    r.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify(SAMPLE),
    }),
  );
  await page.goto("/<route>");
  await page.getByTestId("<stable-testid>").waitFor();
  await page.screenshot({ path: `${ASSETS}/<name>.png`, fullPage: true });
});
```

Run to (re)generate, then add a smoke test asserting the HTML page renders with its `<img>`s.

If the Playwright capture fails (e.g., filesystem permissions or invalid paths), abort CI with an
explicit error message. Include a retry step and write logs to a known location
(e.g. `<project-root>/how-to-test/capture.log`). If write permission is unavailable, write to a
temp directory and fail the build with instructions to fix the path.

## Common mistakes

- Asking the user to manually verify what Playwright can check — automate it; the manual is for
  humans to _re-walk_ flows, not to replace E2E.
- Linking the manual in production — gate the in-app link on a DEV flag; strip the directory from
  production builds.
- Stale screenshots — re-run the capture spec whenever the UI changes; never edit PNGs by hand.
- Documenting headless endpoints without real request/response shapes — pull them from the API
  contract, not memory.
- Writing it before the full suite passes — the manual ships _with_ the delivery, after green.
- Forgetting to update the workspace-level index after adding a new project's manual.
