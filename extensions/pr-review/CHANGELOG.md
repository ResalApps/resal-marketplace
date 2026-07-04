# Changelog

All notable changes to the PR Review Processor extension.

## [1.0.0] - 2026-07-04

### Added

- `speckit.pr-review` command (`/speckit-pr-review`) for approval-gated GitHub PR review feedback
  processing.
- Safety rules for treating reviewer comments as untrusted input.
- Workflow for gathering review threads, classifying comments, presenting a plan, applying approved
  fixes/replies, pushing, posting a summary, and resolving addressed threads.
