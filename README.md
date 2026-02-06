# claude-dream-team

A Claude Code plugin that orchestrates specialized AI agents into a coordinated development team. Run `/epic` to plan and build features end-to-end, or `/bug` to investigate and fix issues through collaborative multi-agent workflows.

<img width="1440" height="870" alt="image" src="https://github.com/user-attachments/assets/4083150a-ee56-4fd2-b5e2-5781faf76cba" />


## Install

**1. Build the `dtq` review queue CLI:**

```bash
cd tools/dtq
go build -o dtq .
```

Make sure the built binary is on your PATH, or the plugin's session-init hook will add it automatically if it finds it at `tools/dtq/dtq`.

**2. Install the plugin in Claude Code:**

```
/install-plugin /path/to/claude-dream-team/dream-team-plugin
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

## Repo Structure

```
tools/
  claude-toggle                   # API provider toggle script (Bash)
  dtq/                          # Review queue CLI (Go)
    main.go                     # CLI dispatch and flag parsing
    queue.go                    # State machine, file I/O, locking
    go.mod
dream-team-plugin/              # Claude Code plugin
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
    team-lead/SKILL.md
    architect/SKILL.md
    product/SKILL.md
    coding/SKILL.md
    code-review/SKILL.md
    qa/SKILL.md
    ui-ux-designer/SKILL.md
    spelunking/SKILL.md
    git-worktree/SKILL.md
    review-queue/SKILL.md
    laws-of-ux/SKILL.md
  hooks/
    hooks.json
    scripts/session-init.sh
```

## Cost Optimization: Routing Agents Through a Proxy

Not every agent needs direct Anthropic API access. Agents like Coding and Product do high-volume, lower-complexity work that can run through a cheaper proxy, while Architect and Code Review benefit from the full API. The included `claude-toggle` script lets you switch modes on the fly so each agent spawns with the right provider.

### How It Works

Dream Team spawns agents in new tmux panes. Each pane inherits the tmux session's environment. `claude-toggle` sets `ANTHROPIC_BASE_URL` and `ANTHROPIC_AUTH_TOKEN` on the tmux environment, so the next agent spawned picks up whichever mode you've toggled to.

### Setup

**1. Install the toggle script:**

```bash
cp tools/claude-toggle ~/.local/bin/
chmod +x ~/.local/bin/claude-toggle
```

**2. Set your proxy credentials** (add to `~/.zshrc`):

```bash
export PROVIDER_URL="https://your-proxy.example.com/api/anthropic"
export PROVIDER_TOKEN="your-token-here"

# Shorthand function
ct() { eval "$(claude-toggle "$@")"; }
```

**3. (Optional) Auto-start in tmux:**

Add to your `~/.tmux.conf` so new sessions start your main claude in direct mode, then set the tmux env to proxy for agents:

```
set-hook -g session-created '\
  set status off ; \
  send-keys "claude" Enter ; \
  run-shell "$HOME/.local/bin/claude-toggle proxy >/dev/null 2>&1"'
```

This starts your main session on direct Anthropic, then flips the tmux env to proxy so spawned agents inherit it.

### Usage

```bash
ct proxy    # Set proxy mode — next spawned agents use your proxy
ct direct   # Set direct mode — next spawned agents use Anthropic API
ct status   # Show current mode
```

### Configuring Per-Agent Modes in CLAUDE.md

Add a section to your project's `CLAUDE.md` so the Team Lead knows which mode to toggle before spawning each agent group. The Team Lead is responsible for running `ct` — subagents should never toggle their own mode.

```markdown
## Agent API Mode Configuration

**The Team Lead is responsible for toggling to the correct mode BEFORE spawning
each agent group.** Agents inherit the tmux environment at spawn time — running
`ct` inside an already-spawned agent does NOT retroactively change its mode.

### Workflow

1. Run `ct proxy` in your shell
2. Spawn all high-volume agents (Coding, Product)
3. Run `ct direct` in your shell
4. Spawn all review/design agents (Architect, Code Review, QA, UI/UX Designer)

Never rely on subagents to switch their own mode after spawning.

### Direct mode (`ct direct`)
Spawn these agents AFTER running `ct direct`:
- **Team Lead**
- **Architect**
- **UI/UX Designer**
- **Code Reviewer**
- **QA**

### Proxy mode (`ct proxy`)
Spawn these agents AFTER running `ct proxy`:
- **Product**
- **Coding**
```

Adjust the split based on your budget and quality requirements.

## Requirements

- Claude Code CLI
- Git (for worktree support)
- Go 1.21+ (for building the `dtq` review queue CLI)
- Node.js (for Playwright tests, when QA agent runs e2e validation)

## License

MIT
