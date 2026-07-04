# Illustration Tools

Generate polished, dark-themed technical diagrams as **self-contained HTML files** (inline SVG + embedded CSS) from a plain-English description. Every diagram opens in any browser and ships with built-in **Copy / PNG / PDF** export.

## Table of Contents

- [Overview](#overview)
- [What It Does](#what-it-does)
- [Prerequisites](#prerequisites)
- [How to Use](#how-to-use)
- [How It Works](#how-it-works)
- [What Gets Created](#what-gets-created)
- [Customization](#customization)
- [Example Session](#example-session)

## Overview

| | |
|---|---|
| **Plugin** | `illustration-tools` |
| **Skills** | `architecture-diagram`, `process-flow-diagram` |
| **Commands** | `/illustration-tools:architecture-diagram`, `/illustration-tools:process-flow-diagram` |
| **Triggers** | "architecture diagram", "system/infrastructure/cloud/network diagram", "process flow", "workflow diagram", "approval flow", "automation sequence" |
| **Output** | A single self-contained `.html` file (inline SVG, embedded CSS), with PNG/PDF export available from the toolbar |
| **Source** | Local |

## What It Does

Two complementary skills, one design language:

| Skill | Use it for | Shape language |
|-------|------------|----------------|
| **`architecture-diagram`** | Non-sequential system relationships — components, infrastructure, cloud topology, security zones, network maps | Component boxes, free-form connections, security/region boundaries |
| **`process-flow-diagram`** | Sequential workflows — approval flows, automation pipelines, runbooks, onboarding, decision trees | Numbered step boxes, decision diamonds, ordered/labeled arrows |

Both produce a dark-themed (`#020617` slate-950), JetBrains-Mono, semantically color-coded diagram with a built-in export toolbar — so diagrams from anyone on the team read the same way.

The `devtools` PR and How-To-Test workflows can also call these skills automatically when a feature
changes architecture or process flow. The generated documentation stores the diagram HTML source and
an exported PNG beside the feature docs, embeds the PNG, and links back to the editable HTML source.

## Prerequisites

- None to generate. The output is a standalone HTML file that renders offline in any modern browser.
- The **export toolbar** loads two CDN scripts (`html2canvas@1.4.1`, `jspdf@2.5.2`, both SRI-pinned), so Copy/PNG/PDF need network access the first time. The diagram itself renders without them.
- Clipboard copy needs a user gesture and a secure context (https / file / localhost).

## How to Use

Install from the Resal marketplace:

```
/plugin install illustration-tools@resal
```

Then describe what you want — the skills trigger automatically, or invoke them directly:

```
/illustration-tools:architecture-diagram   # then describe your system
/illustration-tools:process-flow-diagram    # then describe your workflow
```

In plain language:

- *"Draw an architecture diagram for a React frontend, Node API, Postgres, and Redis on AWS with CloudFront."*
- *"Make a process flow for expense approvals with a manager decision step and a rejection branch."*

Iterate in chat and Claude edits the same file: *"add a Redis cache"*, *"add a rejection branch from step 3"*, *"wrap this to a second row"*, *"make the API tier wider"*.

## How It Works

Each skill is **instructions + a template**, not a program:

1. The skill's `SKILL.md` encodes the full design system — color palette per component/step type, typography, shape language, spacing rules, and (for process flows) the viewBox layout math that prevents right-edge clipping.
2. Claude copies `resources/template.html` and customizes it for your description — placing boxes, drawing arrows, filling summary cards.
3. The output is one self-contained `.html` file with a collapsible `⋯` export toolbar (📋 Copy / 🖼️ PNG / 📄 PDF), all driven by a single `html2canvas` capture so the PDF preserves the dark theme.

Full internals and a customization guide live in the per-skill READMEs:

- [`architecture-diagram` README](../plugins/illustration-tools/skills/architecture-diagram/README.md)
- [`process-flow-diagram` README](../plugins/illustration-tools/skills/process-flow-diagram/README.md)

## What Gets Created

The plugin itself:

```
plugins/illustration-tools/
├── .claude-plugin/
│   └── plugin.json
├── README.md
└── skills/
    ├── architecture-diagram/
    │   ├── SKILL.md
    │   ├── README.md
    │   ├── resources/template.html
    │   └── examples/            # web-app, aws-serverless, microservices
    └── process-flow-diagram/
        ├── SKILL.md
        ├── README.md
        ├── resources/template.html
        └── examples/            # sprint-report, ai-governance, it-change, inventory
```

Each **run** produces a single `.html` diagram file wherever you ask Claude to write it.

## Customization

- **One diagram** — ask Claude to tweak the generated file, or edit the SVG by hand.
- **The default look for all future diagrams** — edit the skill's `resources/template.html`.
- Common knobs: recolor a component/step type (keep fills semi-transparent), resize the `viewBox`, swap the Google Font, edit the summary cards, or remove the export toolbar. For process flows, keep the three width numbers (`viewBox` width, `svg min-width`, `.container max-width − 48`) in sync to avoid a clipped right edge.

See each skill's README for the full customization table and the constraints to respect (self-contained output, no `<foreignObject>`, preserve the export capture anchors).

## Example Session

```
You:   Create an architecture diagram for a SaaS app:
       - React frontend behind CloudFront
       - Node/Express API on ECS
       - PostgreSQL (RDS) and Redis (ElastiCache)
       - Cognito for auth

Claude: [activates architecture-diagram, copies the template, places the
        components with semantic colors, draws the connections, fills the
        summary cards] → writes saas-architecture.html

You:   Add a Kafka event bus between the API and a new notifications service.

Claude: [edits the same file — inserts an orange message-bus connector and the
        new emerald service box, re-routes the arrows]

You:   Open saas-architecture.html and click 📄 PDF to drop it into the deck.
```
