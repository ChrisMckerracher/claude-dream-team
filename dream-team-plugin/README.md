# claude-dream-team

A Claude Code plugin that orchestrates specialized AI agents into a coordinated development team. Run `/epic` to plan and build features end-to-end, or `/bug` to investigate and fix issues through collaborative multi-agent workflows.

## Install

From within Claude Code, add the marketplace and install the plugin:

```
/plugin marketplace add ChrisMckerracher/claude-dream-team
/plugin install dream-team@claude-dream-team
```

## What It Does

Dream Team turns Claude Code into a full development shop. Instead of one agent doing everything, specialized agents handle what they're best at:

| Agent | Model | Role |
|-------|-------|------|
| **Team Lead** | Opus | Orchestrates workflows, decomposes work into task DAGs, manages the review pipeline |
| **Architect** | Opus | Creates technical design docs, makes architecture decisions, resolves design drift |
| **Product** | Sonnet | Writes product briefs, Gherkin `.feature` files, user stories, acceptance criteria |
| **Coding** | Sonnet | Implements features in git worktrees, TDD, spelunk-based code exploration |
| **Code Review** | Sonnet | Reviews changes for correctness, security (OWASP), style, and test coverage |
| **QA** | Sonnet | Validates against product specs, writes Playwright tests with video recording |
| **UI/UX Designer** | Sonnet | Scans design systems, applies Laws of UX, writes design specs |

## Commands

### `/epic` - Build a Feature

Runs the full development lifecycle:

```
Planning Phase
  Team Lead spawns Product + Architect in parallel
  Product writes briefs and .feature files
  Architect writes technical design doc
  Both communicate and align as they work
  Team Lead reviews, iterates, approves
  Work decomposed into a DAG of bite-sized tasks

Execution Phase
  Coding agents work in isolated git worktrees
  Code Review agent gates all changes
  QA agent validates against product specs
  Pipeline: Coding -> Code Review -> QA -> Merge

Validation Phase
  QA decomposes all features into Playwright test suites
  Full flow testing with video recording
  Broken flows escalate for fixes
```

### `/bug` - Investigate a Bug

Collaborative investigation workflow:

```
Team Lead theorizes investigation leads
Spawns investigators (Coding/QA agents) per lead
Agents explore, theorize, and challenge each other
Build consensus on root cause
Lightweight fix -> single agent implements
Complex fix -> transitions to /epic workflow
```

### `/status` - Check Progress

Shows task progress, agent assignments, review pipeline state, and blockers.

## Key Features

### Spelunk System

Persistent codebase exploration with hash-based staleness tracking. Agents don't re-read the same code - spelunk docs are generated once and reused until source files change.

```
docs/spelunk/
  contracts/     # Type defs, API signatures (Architect, QA)
  flows/         # User flows, entry points (Product)
  boundaries/    # Module edges, dependencies (Architect)
  trust-zones/   # Auth boundaries (Security)
  _staleness.json  # SHA-256 hash tracking per source file
```

### Git Worktree Isolation

Each coding agent works in its own worktree, so multiple tasks can be implemented in parallel without conflicts:

```
project-root/
../worktrees/
  coder-1-task-42/   # Agent 1's isolated workspace
  coder-2-task-43/   # Agent 2's isolated workspace
```

### Review Pipeline (`dtq`)

Enforced quality gates via the `dtq` CLI — a lightweight Go binary that manages queue state, priority ordering, and cycle tracking:

```bash
dtq submit <task-id> --branch <branch>   # Coding agent submits for review
dtq claim review                          # Code Review claims next item
dtq approve <task-id>                     # Advance: review -> qa -> merge-ready
dtq reject <task-id> --reason "..."       # Send back with feedback
dtq status                                # View queue grouped by stage
```

Pipeline: `coding -> review -> qa -> merge-ready`. Revisions get priority (LRU). Auto-escalation warning at 3+ review cycles. State persists in `.dtq/queue.json`.

### Laws of UX Reference

Complete reference of all 30 Laws of UX (from lawsofux.com) built into the UI/UX Designer's skill set. Every design decision can reference the relevant principles.

### Safety Hooks

- **Session init**: Creates required directory structure on startup
- **Worktree guard**: Validates worktree naming conventions before creation
- **Destructive git protection**: Blocks `git push --force`, `git reset --hard`, `git clean -f`
- **Spelunk staleness**: Reminds agents to update hash tracking after doc changes
- **Subagent monitoring**: Flags incomplete tasks when agents stop

## Plugin Structure

```
.claude-plugin/plugin.json    # Plugin manifest
agents/                       # 7 agent definitions
  team-lead.md
  architect.md
  product.md
  coding.md
  code-review.md
  qa.md
  ui-ux-designer.md
commands/                     # 3 slash commands
  epic.md
  bug.md
  status.md
skills/                       # 11 skill modules
  team-lead/SKILL.md          # Orchestration patterns, DAG templates
  architect/SKILL.md          # ADR templates, drift resolution
  product/SKILL.md            # User story frameworks, Gherkin patterns
  coding/SKILL.md             # TDD cycle, worktree workflow
  code-review/SKILL.md        # Review checklists, feedback templates
  qa/SKILL.md                 # Playwright patterns, failure reports
  ui-ux-designer/SKILL.md     # Design spec templates, a11y guidelines
  spelunking/SKILL.md         # Hash-based code exploration system
  git-worktree/SKILL.md       # Worktree lifecycle management
  review-queue/SKILL.md       # Review pipeline protocols
  laws-of-ux/SKILL.md         # All 30 UX laws with practical guidance
tools/
  dtq/                        # Review queue CLI (Go)
    main.go                   # CLI dispatch and flag parsing
    queue.go                  # State machine, file I/O, locking
    go.mod
hooks/
  hooks.json                  # Event handler configuration
  scripts/session-init.sh     # Directory scaffolding + dtq build
```

## Requirements

- Claude Code CLI
- Git (for worktree support)
- Go 1.21+ (for building the `dtq` review queue CLI — auto-built on first session)
- Node.js (for Playwright tests, when QA agent runs e2e validation)

## Setup

The plugin is mostly self-configuring. On first session, the `SessionStart` hook:
1. Creates spelunk, plans, and worktree directories
2. Builds the `dtq` binary from source (`tools/dtq/`) and adds it to PATH

If the auto-build fails (e.g., Go not installed), build manually:

```bash
cd <plugin-root>/tools/dtq
go build -o dtq .
```

## License

MIT
