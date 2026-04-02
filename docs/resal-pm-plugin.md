# Resal PM Plugin

AI-first product management plugin for the Resal team, powered by PM.md philosophy and Roadmap Methodology 2.1.

## Table of Contents

- [Overview](#overview)
- [Skills](#skills)
  - [evaluate-idea](#evaluate-idea)
  - [write-spec](#write-spec)
  - [prd-to-spec](#prd-to-spec)
  - [solution-analyst](#solution-analyst)
  - [competitive-brief](#competitive-brief)
  - [stakeholder-update](#stakeholder-update)
  - [research-discovery](#research-discovery)
  - [data-analysis](#data-analysis)
- [Commands](#commands)
  - [philosophy](#philosophy)
- [Installation](#installation)
- [Source Repository](#source-repository)

---

## Overview

| | |
|---|---|
| **Plugin name** | `resal-pm-plugin` |
| **Version** | 1.3.0 |
| **Skills** | 8 |
| **Commands** | 1 |
| **Source repo** | [ResalApps/AI_Workflow](https://github.com/ResalApps/AI_Workflow) (path: `resal-pm-plugin/`) |

## Skills

### evaluate-idea

Evaluate whether a product idea, feature request, or initiative is worth building.

**Triggers:** "I have an idea", "should we build X?", "evaluate this feature", "assess this bet", "is this worth building?"

```
/resal-pm-plugin:evaluate-idea
```

### write-spec

Write product requirement documents (PRDs) with structured formatting.

**Triggers:** "write a PRD", "create a spec", "draft product requirements", "write user stories", "spec this out"

```
/resal-pm-plugin:write-spec
```

### prd-to-spec

Decompose a PRD into technical specifications and implementation tasks.

**Triggers:** "break down this PRD", "create specs from PRD", "decompose requirements"

```
/resal-pm-plugin:prd-to-spec
```

### solution-analyst

Analyze technical solutions against the service catalog and microservice architecture.

**Triggers:** "analyze this solution", "which service handles X?", "microservice analysis"

```
/resal-pm-plugin:solution-analyst
```

### competitive-brief

Analyze competitors, market positioning, and feature comparisons.

**Triggers:** "competitors", "competitive landscape", "market positioning", "feature comparison", "what is [company] doing?"

```
/resal-pm-plugin:competitive-brief
```

### stakeholder-update

Write status updates, weekly reports, leadership updates, and meeting preparation materials.

**Triggers:** "write a status update", "prepare a weekly report", "draft a leadership update", "create a monthly review", "help me prepare for my meeting with [stakeholder]"

```
/resal-pm-plugin:stakeholder-update
```

### research-discovery

Research topics, analyze user feedback, synthesize interviews, size opportunities, and understand markets.

**Triggers:** "research a topic", "analyze user feedback", "synthesize interview notes", "size an opportunity", "understand a market"

```
/resal-pm-plugin:research-discovery
```

### data-analysis

Analyze metrics, build dashboards, set OKRs, investigate metric changes, and run metrics reviews.

**Triggers:** "analyze metrics", "review our numbers", "build a dashboard", "set OKRs", "investigate why [metric] changed"

```
/resal-pm-plugin:data-analysis
```

## Commands

### philosophy

Display Resal's product philosophy and how it powers every skill in the plugin.

```
/resal-pm-plugin:philosophy
```

## Installation

### Via Resal Marketplace

```
/plugin marketplace add ResalApps/resal-marketplace
/plugin install resal-pm-plugin@resal
```

### Direct from source repo

```bash
claude --plugin-dir /path/to/AI_Workflow/resal-pm-plugin
```

## Source Repository

This plugin is maintained in [ResalApps/AI_Workflow](https://github.com/ResalApps/AI_Workflow) under the `resal-pm-plugin/` directory. The marketplace references it directly from that repo, so updates to the source are automatically picked up.

```
AI_Workflow/
└── resal-pm-plugin/
    ├── .claude-plugin/plugin.json
    ├── commands/
    │   └── philosophy.md
    └── skills/
        ├── competitive-brief/
        ├── data-analysis/
        ├── evaluate-idea/
        ├── prd-to-spec/
        ├── research-discovery/
        ├── solution-analyst/
        ├── stakeholder-update/
        └── write-spec/
```
