# Contributing a New Plugin

Guide for adding new plugins to the Resal Marketplace.

## Table of Contents

- [Plugin Structure](#plugin-structure)
- [Step-by-Step Guide](#step-by-step-guide)
- [Writing Documentation](#writing-documentation)

---

## Plugin Structure

Each plugin lives under `plugins/` and follows this structure:

```
plugins/my-plugin/
├── .claude-plugin/
│   └── plugin.json              # Plugin manifest (required)
└── skills/
    └── my-skill/
        ├── SKILL.md             # Skill instructions (required)
        └── references/          # Supporting docs (optional)
            └── *.md
```

## Step-by-Step Guide

### 1. Create the plugin directory

```bash
mkdir -p plugins/my-plugin/.claude-plugin
mkdir -p plugins/my-plugin/skills/my-skill/references
```

### 2. Create `plugin.json`

```json
{
  "name": "my-plugin",
  "description": "What the plugin does",
  "version": "1.0.0"
}
```

### 3. Create `SKILL.md`

```markdown
---
name: my-skill
description: When to trigger this skill. Be specific about trigger phrases.
---

# My Skill

Instructions for Claude when this skill is activated.
```

### 4. Register in marketplace

Add an entry to `.claude-plugin/marketplace.json` at the repo root:

```json
{
  "name": "my-plugin",
  "source": "./plugins/my-plugin",
  "description": "What the plugin does"
}
```

### 5. Add documentation

Create `docs/my-plugin.md` with a TOC and usage guide, and add a row to the plugins table in `docs/README.md`.

### 6. Test locally

```bash
claude --plugin-dir ./plugins/my-plugin
```

Use `/reload-plugins` to pick up changes without restarting.

### 7. Submit a PR

Create a branch, commit, and open a pull request.

## Writing Documentation

Each plugin doc in `docs/` should include:

- **Table of Contents** at the top
- **Overview** table (name, command, triggers)
- **What It Does** section
- **Prerequisites**
- **How to Use** with trigger examples
- **Workflow** breakdown by phase
- **What Gets Created** with file tree
- **Example Session** showing a real interaction
