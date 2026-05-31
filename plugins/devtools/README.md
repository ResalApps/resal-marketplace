# Devtools

Developer productivity tools for Resal engineering workflows.

## Included Skills

| Skill | Description |
|---|---|
| `pr-review` | Process GitHub PR review comments, plan fixes or replies, apply approved changes, push, and resolve addressed threads. |
| `resal-standards-review` | Review/audit any Resal project against the **Resal Engineering Standards**. Auto-detects the stack (Python/FastAPI, .NET, React web, or React Native), produces a severity-rated **Compliance & Gaps Report**, and — in full mode — asks which severity tiers to fix before generating a **Remedy Plan**. Supports **report-only** mode. |

## Usage

Install from the Resal marketplace:

```
/plugin install devtools@resal
```

### pr-review

```
/devtools:pr-review ResalApps/example-repo#123
```

### resal-standards-review

Ask Claude to review a project against the Resal standards, or invoke the skill directly:

```
/devtools:resal-standards-review            # then point it at a project path
```

- **Full mode (default):** report → asks which severity tiers (critical/high/medium/nice-to-have) → remedy plan.
- **Report-only:** say "report only" (or "audit only" / "no remedy") to stop at the report.
- The skill **auto-detects** the stack from marker files (`*.csproj`/`*.sln` → .NET, `package.json` + `react-native`/`expo` → React Native, `package.json` + `react`/`next` → React web, `pyproject.toml`/`app/` → Python) and loads the matching rules. Mixed-stack repos are reported per stack.

The full prose standards (`core.md` + per-stack files) are **bundled** with the skill under `skills/resal-standards-review/standards/`; the skill's `checks-*.md` catalogs are self-sufficient even without them.
