# Changelog

All notable changes to the Detailed PR Generator extension.
Format follows [Keep a Changelog](https://keepachangelog.com/).

## [1.0.0] — 2026-06-11

### Added
- `speckit.pr.generate` command (`/speckit-pr-generate`): generates a feature `CHANGELOG.md` and a
  plain-English `<Feature>-Explained.md` under `docs/<feature-slug>/` from Spec Kit artifacts, then
  creates or updates the pull request description with the feature details under the heading
  **"What have been developed and how to review it"**.
- Idempotency markers (`<!-- speckit-pr:start -->` / `<!-- speckit-pr:end -->`) so re-runs refresh
  the PR section instead of duplicating it.
- Optional `after_implement` lifecycle hook.
- Graceful degradation when `gh`/`git`/remote are unavailable (docs still generated, PR step skipped).
