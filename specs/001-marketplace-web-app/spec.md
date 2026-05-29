# Feature Specification: Resal Marketplace Web Application

**Feature Branch**: `001-marketplace-web-app`  
**Created**: April 2, 2026  
**Status**: Draft  
**Input**: User description: "Resal Marketplace Web Application - A self-hosted web application for browsing, searching, viewing details, and submitting Claude Code plugins to the Resal Marketplace repository"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Browse Plugin Catalog (Priority: P1)

As a Resal engineer, I want to browse a visual catalog of all available Claude Code plugins and their skills so I can discover tools that help me work faster, without having to navigate GitHub directly.

**Why this priority**: This is the core value proposition — the entire purpose of the web app is to make the marketplace browsable. Without browsing, no other feature matters. This alone replaces the painful workflow of reading raw JSON and folder structures on GitHub.

**Independent Test**: Can be fully tested by loading the web app and verifying that all plugins from the marketplace repository appear as cards in a grid, each showing name, description, tags, and skill count. Delivers immediate value by replacing manual GitHub navigation.

**Acceptance Scenarios**:

1. **Given** the marketplace contains 2+ plugins, **When** a user opens the home page, **Then** all plugins are displayed as cards in a responsive grid layout with name, description, version, author, tags, and number of skills
2. **Given** a user is on the catalog page, **When** they click on a plugin card, **Then** they are taken to the plugin detail page showing the full description, metadata, skills list, and keywords
3. **Given** a user is on the home page, **When** they view the page, **Then** they see a hero section with a search bar and a featured plugins grid showing the most recently updated plugins
4. **Given** plugins have tags assigned, **When** a user views the catalog, **Then** each plugin card displays colored tag badges for easy visual scanning
5. **Given** the catalog is empty because the initial sync has not completed, **When** a user opens the home page, **Then** they see a loading/syncing indicator with the message "Syncing plugins from repository..."

---

### User Story 2 - Search Across Plugins (Priority: P2)

As a Resal engineer, I want to search across all plugin names, descriptions, skill documentation, and reference materials so I can quickly find relevant tools for my current task.

**Why this priority**: Search is the second most critical capability — once users can see plugins exist, they need to find specific ones. Full-text search across all content (including skill docs and references) is a major improvement over GitHub's limited search.

**Independent Test**: Can be tested by typing a search query (e.g., "deployment") and verifying that results include matching plugins, skills, and references ranked by relevance. Works standalone even if submission features aren't built yet.

**Acceptance Scenarios**:

1. **Given** the search index contains plugins with "deployment" in their descriptions, **When** a user types "deployment" in the search bar, **Then** matching plugins are displayed with highlighted relevant text
2. **Given** a skill's SKILL.md contains the word "helm", **When** a user searches for "helm", **Then** the parent plugin appears in results with context showing the match came from a skill document
3. **Given** a reference document contains "infrastructure", **When** a user searches for "infrastructure", **Then** the parent plugin appears in results
4. **Given** a user has entered a search query, **When** they want to narrow results, **Then** they can filter by tag and sort by relevance or recency
5. **Given** there are many search results, **When** the user views results, **Then** results are paginated with controls to navigate between pages
6. **Given** a user searches for a term with no matches, **When** results load, **Then** a "No results found — try different keywords" message is displayed

---

### User Story 3 - View Detailed Plugin & Skill Documentation (Priority: P3)

As a Resal engineer, I want to view the full rendered documentation for a plugin's skills and reference materials so I can understand how to use a plugin without reading raw markdown files on GitHub.

**Why this priority**: Once users find a plugin, they need detailed documentation to evaluate and use it. Rendering markdown with proper formatting, syntax highlighting, and navigation is a significant UX improvement over raw GitHub views.

**Independent Test**: Can be tested by navigating to a plugin detail page and verifying that skill documentation renders correctly with proper markdown formatting, code syntax highlighting, and a sidebar for navigating between reference documents.

**Acceptance Scenarios**:

1. **Given** a plugin has one or more skills, **When** a user views the plugin detail page, **Then** they see tabs for Overview, Skills, and Metadata, and the Skills tab lists all skills with their names and descriptions
2. **Given** a skill has a SKILL.md with markdown content, **When** a user opens the skill detail page, **Then** the SKILL.md is fully rendered with proper headings, code blocks with syntax highlighting, lists, and links
3. **Given** a skill has reference documents, **When** a user views the skill detail page, **Then** a sidebar shows links to all reference documents, and clicking one renders the reference content in the main panel
4. **Given** a user is on a skill detail page, **When** they look at the page, **Then** breadcrumbs show "Marketplace > Plugin Name > Skill Name" for navigation context
5. **Given** a plugin has metadata (version, author, keywords, source info), **When** a user views the Metadata tab, **Then** all metadata is displayed clearly

---

### User Story 4 - Submit a New Plugin (Priority: P4)

As a Resal engineer, I want to submit a new plugin or skill through a guided form so I can contribute to the marketplace without manually creating Git branches, writing JSON configs, and opening PRs.

**Why this priority**: Submission is the "write" side of the marketplace. It's important for growth but secondary to read/browse/search since most users will be consumers before they become contributors. The manual PR process works as a fallback.

**Independent Test**: Can be tested by going through the multi-step submission form, filling in plugin metadata, skill content, and reference docs, then verifying that a PR is created on GitHub with all the correct files.

**Acceptance Scenarios**:

1. **Given** an authenticated user wants to add a plugin, **When** they open the submit page, **Then** they see a multi-step form with clear step indicators (Plugin Info → Skill Editor → Review → Submitted)
2. **Given** a user has filled in plugin name, description, version, author, and keywords, **When** they proceed to the skill editor step, **Then** they can write or paste SKILL.md content in a markdown editor with live preview
3. **Given** a user is defining a skill, **When** they add reference documents, **Then** they can specify filenames and content for each reference
4. **Given** a user has completed all form steps, **When** they review and confirm submission, **Then** the system creates a Git branch, writes all files (plugin.json, SKILL.md, references, updated marketplace.json), and opens a pull request
5. **Given** a submission has been created, **When** the user views the confirmation page, **Then** they see the PR URL, branch name, and a message explaining that the plugin will appear after review and merge
6. **Given** a user has previously submitted plugins, **When** they visit the "My Submissions" page, **Then** they see a list of their PRs with status (open, merged, closed/declined, or closed/withdrawn)

---

### User Story 5 - Administrator Manages Marketplace (Priority: P5)

As a marketplace administrator, I want to trigger manual syncs, view marketplace statistics, and manage tags so I can keep the catalog accurate and organized.

**Why this priority**: Admin features support the operational health of the marketplace but are not needed by the majority of users. Scheduled sync handles most cases automatically.

**Independent Test**: Can be tested by calling admin endpoints and verifying sync triggers correctly, stats are accurate, and the system reflects the latest state of the Git repository.

**Acceptance Scenarios**:

1. **Given** new plugins have been merged to the repository, **When** an admin triggers a manual sync, **Then** the system re-reads the repository and updates the catalog with new/changed plugins
2. **Given** an admin wants to check marketplace health, **When** they view stats, **Then** they see total plugin count, skill count, reference count, last sync time, and sync status
3. **Given** the sync process is running, **When** a user queries sync status, **Then** they see whether sync is idle, in progress, or in an error state

---

### Edge Cases

- What happens when a plugin's source repository is unavailable (external plugin)? The system should display cached data and mark the plugin as "source temporarily unavailable"
- What happens when two users submit plugins with the same name simultaneously? The system should validate against current marketplace state and reject duplicates before creating a branch
- What happens when GitHub API rate limits are hit during sync? The system should use conditional requests (caching), retry with backoff, and show the last known good state
- What happens when a SKILL.md file is very large (over 500KB)? The system should index the content for search but may truncate display in listing views
- What happens when a PR created by the submission system has merge conflicts? The PR should include merge instructions and the user should be notified to resolve conflicts
- What happens when the system starts up for the first time with no cached data? It should perform a full sync from the Git repository before serving content
- What happens when a user tries to access a plugin that was recently removed from the repo? The system should show a "not found" message since the database reflects the repo state

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST display all plugins from the marketplace repository in a visual catalog with name, description, version, author, keywords, tags, and skill count
- **FR-002**: System MUST provide a home page with a hero section, prominent search bar, and a featured plugins grid showing the most recently updated plugins (sorted by `updated_at`, newest first)
- **FR-003**: System MUST provide a plugin detail page showing plugin metadata, skills list, and documentation organized in tabs (Overview, Skills, Metadata)
- **FR-004**: System MUST render SKILL.md and reference documents as formatted markdown with syntax-highlighted code blocks
- **FR-005**: System MUST provide full-text search across plugin names, descriptions, keywords, skill descriptions, skill documentation, and reference content
- **FR-006**: System MUST support search filtering by tag and sorting by relevance or recency
- **FR-007**: System MUST paginate all list views (plugin catalog, search results) with page navigation controls
- **FR-008**: System MUST provide breadcrumb navigation showing the path: Marketplace > Plugin > Skill
- **FR-009**: System MUST support a skill detail page with rendered SKILL.md content and a sidebar listing reference documents
- **FR-010**: System MUST display reference documents in the main content panel when selected from the sidebar
- **FR-011**: System MUST allow unauthenticated users to browse plugins, search, and view all documentation freely; authentication via the organization's single sign-on provider (Microsoft Entra ID) is required only for submissions, viewing personal submissions, and admin actions
- **FR-012**: System MUST provide a multi-step submission form for contributing new plugins, including plugin metadata entry, skill content editing with markdown preview, and reference document attachment
- **FR-013**: System MUST validate submission payloads for required fields, correct name format, and duplicate plugin names before creating any Git resources
- **FR-014**: System MUST create a Git branch via a backend service account (GitHub App or bot PAT), write all plugin files (plugin.json, SKILL.md, references), update the marketplace registry, and open a pull request with the submitting user attributed in the PR description
- **FR-015**: System MUST return a PR URL and branch name to the user after successful submission
- **FR-016**: System MUST provide a "My Submissions" page listing the user's pull requests with their status (open, merged, closed/declined, closed/withdrawn)
- **FR-017**: System MUST sync plugin data from the Git repository to a local data store on startup and on a scheduled interval (every 5 minutes)
- **FR-018**: System MUST support manual sync triggers for administrators to re-index the catalog immediately after merges
- **FR-019**: System MUST display marketplace statistics including total plugin count, skill count, reference count, and last sync timestamp
- **FR-020**: System MUST handle both local plugins (within the marketplace repo) and external plugins (from other repositories)
- **FR-021**: System MUST assign roles (Anonymous Viewer, Authenticated Contributor, Admin) with appropriate permissions — unauthenticated users can browse, search, and read all documentation; all authenticated users receive Contributor role by default (can submit plugins)
- **FR-022**: System MUST be deployable as a containerized application with persistent storage for the local database
- **FR-023**: System MUST provide a health check endpoint for monitoring deployment status
- **FR-024**: System MUST support responsive design that works on desktop and mobile devices
- **FR-025**: System MUST support dark mode as a user preference toggle
- **FR-026**: System MUST display helpful empty-state messaging — a loading/syncing indicator when the catalog is empty during initial startup, and a "No results found — try different keywords" message when search returns zero results

### Key Entities

- **Plugin**: A Claude Code plugin registered in the marketplace. Key attributes: unique identifier, display name, description, version, author, source path (local or external repository), keywords, and timestamps. One plugin contains many Skills.
- **Skill**: A capability within a plugin, defined by a SKILL.md file. Key attributes: unique identifier, name, description, full markdown content, and display order. One Skill belongs to one Plugin and contains many References.
- **Reference**: A supplementary markdown document attached to a skill. Key attributes: unique identifier, filename, full content, and display order. One Reference belongs to one Skill.
- **Tag**: A category label for organizing and filtering plugins. Key attributes: identifier, display label, and display color. Tags are shared across plugins (many-to-many relationship).
- **Submission**: A request to add a new plugin, tracked as a pull request. Key attributes: identifier, status, PR URL, branch name, and associated user. Lifecycle states: "open" (PR active) → "merged" (accepted into marketplace) | "closed/declined" (rejected by reviewer) | "closed/withdrawn" (cancelled by submitter).
- **Sync State**: A singleton record tracking the last synchronization with the Git repository. Key attributes: last commit SHA, last sync timestamp, and current status (idle, syncing, error).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can discover and browse all available plugins within 10 seconds of opening the web application
- **SC-002**: Search returns relevant results across all content (plugins, skills, references) in under 1 second for typical queries
- **SC-003**: Plugin detail pages render full markdown documentation with proper formatting and syntax highlighting
- **SC-004**: Users can complete a plugin submission through the guided form in under 10 minutes
- **SC-005**: The catalog reflects newly merged plugins within 5 minutes (scheduled sync interval)
- **SC-006**: The application supports up to 50 concurrent users without performance degradation
- **SC-007**: All form validations prevent invalid or duplicate submissions with clear error messages
- **SC-008**: The application works on both desktop and mobile screen sizes

## Clarifications

### Session 2026-04-02

- Q: Should unauthenticated users be able to browse/search plugins, or is authentication required for all features? → A: Browse/search/view docs freely; auth required only for submissions and admin actions
- Q: What determines which plugins appear in the "featured plugins grid" on the home page? → A: Most recently updated plugins (sorted by updated_at timestamp, newest first)
- Q: What are the submission lifecycle states and transitions? → A: Three final states: "merged" (accepted), "closed/declined" (rejected by reviewer), "closed/withdrawn" (cancelled by submitter)
- Q: What do users see during first-time startup (empty catalog) or when search returns zero results? → A: Helpful empty-state messaging — "Syncing plugins..." during initial load, "No results found — try different keywords" for empty search
- Q: Who owns the GitHub token for creating submission PRs — individual users or a backend service account? → A: Backend service account (GitHub App or bot PAT) — PRs are created by a bot identity, attributed to the submitting user in the PR description

## Assumptions

- Users are internal Resal engineering team members (approximately 10-50 developers) with stable network connectivity
- The organization uses Microsoft Entra ID (Azure AD) for identity management, which will be reused for authentication
- The Git repository (ResalApps/resal-marketplace) is the single source of truth for all plugin data
- A backend service account (GitHub App or bot PAT) is used for all GitHub write operations; submission PRs are created by a bot identity with the submitting user attributed in the PR description
- All plugin data fits comfortably in a lightweight database (the marketplace is not expected to exceed hundreds of plugins)
- Plugin versioning history, user ratings/comments, automated plugin testing, and real-time webhook sync are out of scope for v1
- The application will be deployed on internal infrastructure using container orchestration consistent with existing Resal patterns
- Contributors will follow the existing plugin documentation standards when writing SKILL.md and reference documents
- External plugins (from other repositories) may occasionally be unavailable — graceful degradation is expected
- Administrators will manually trigger syncs only after PR merges until webhook-based automation is added in a future version
