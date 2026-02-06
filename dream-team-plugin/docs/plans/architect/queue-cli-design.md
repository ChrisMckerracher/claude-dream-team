---
epic: "Review Queue CLI Tool"
status: draft
created: 2026-02-06
dependencies: []
---

# Technical Design: `dtq` — Dream Team Queue CLI

## Overview

A single Go binary (`dtq`) that agents call via Bash to manage the review queue. 5 subcommands, JSON file store, stdlib only. ~300 lines of Go.

## Architecture Decisions

### AD-1: Go CLI, not MCP server
- **Decision**: Single binary with subcommands, invoked via Bash
- **Rationale**: Agents already have Bash. MCP added unnecessary complexity.

### AD-2: JSON file store at `.dtq/queue.json`
- **Decision**: Store queue state in `.dtq/queue.json` relative to repo root
- **Rationale**: Keeps queue state with the project. <50 items max. Human-readable, debuggable.

### AD-3: stdlib only, no external dependencies
- **Decision**: No cobra, no third-party packages
- **Rationale**: 5 subcommands don't need a framework. `os.Args` switching is sufficient.

### AD-4: Task ID as primary key
- **Decision**: Queue items are keyed by task ID (no separate queue ID)
- **Rationale**: Task IDs are already unique. Extra IDs add confusion. Agents think in task IDs.

### AD-5: Build from source via `go build`
- **Decision**: SessionStart hook auto-builds if binary missing
- **Rationale**: Go compiles in <2s. Avoids committing platform-specific binaries.

## Project Layout

```
dream-team-plugin/
  tools/
    dtq/
      main.go          # Entry point, subcommand dispatch, flag parsing
      queue.go         # Data types, state machine, file I/O, locking
      queue_test.go    # Tests
      go.mod           # module dream-team/dtq
```

## Subcommands

### `dtq submit <task-id> --branch <branch>`
Coding agent submits work for review. Creates item in `review` stage.
- Positional: `task-id` (required)
- Flag: `--branch` (required)
- Fails if task-id already in queue and not in `coding` stage

### `dtq claim <stage>`
Claims next available item in stage (`review` or `qa`). Sets `claimedBy`.
- Positional: `stage` (required, one of: review, qa)
- Priority: revisions first (items with cycles > 0), then FIFO by submittedAt
- Fails if no unclaimed items in that stage

### `dtq approve <task-id>`
Advances item to next stage. Clears `claimedBy` for next stage.
- `review` -> `qa`
- `qa` -> `merge-ready`
- Fails if item not claimed or not in review/qa

### `dtq reject <task-id> --reason <text>`
Sends item back to `coding`. Increments cycle count. Records reason.
- Flag: `--reason` (required)
- Prints escalation warning at 3+ cycles
- Fails if item not in review/qa

### `dtq status [task-id]`
Without arg: full queue grouped by stage with counts.
With arg: single item detail including history.

## State Machine

```
coding --submit--> review --approve--> qa --approve--> merge-ready
  ^                  |                  |
  +---reject---------+                  |
  +---reject----------------------------+
```

Valid transitions only. Any other transition returns error + exit code 1.

| From | Action | To |
|------|--------|----|
| (new/coding) | submit | review |
| review | approve | qa |
| review | reject | coding |
| qa | approve | merge-ready |
| qa | reject | coding |

## Data Model

```go
type HistoryEntry struct {
    Action string `json:"action"`    // submit, claim, approve, reject
    Agent  string `json:"agent"`
    At     string `json:"at"`        // RFC3339
    Note   string `json:"note,omitempty"`
}

type QueueItem struct {
    TaskID      string         `json:"taskId"`
    Stage       string         `json:"stage"`       // coding|review|qa|merge-ready
    Branch      string         `json:"branch"`
    ClaimedBy   string         `json:"claimedBy,omitempty"`
    Cycles      int            `json:"cycles"`
    SubmittedAt string         `json:"submittedAt"` // RFC3339
    UpdatedAt   string         `json:"updatedAt"`   // RFC3339
    History     []HistoryEntry `json:"history"`
}

type Queue struct {
    Items map[string]*QueueItem `json:"items"` // keyed by taskId
}
```

Note: `Items` is a map, not a slice. Keyed by task ID for O(1) lookup.

## File Locking

```go
func withLock(fn func(*Queue) error) error {
    // Ensure .dtq/ directory exists
    os.MkdirAll(".dtq", 0755)
    f, err := os.OpenFile(".dtq/queue.json", os.O_RDWR|os.O_CREATE, 0644)
    if err != nil { return err }
    defer f.Close()
    if err := syscall.Flock(int(f.Fd()), syscall.LOCK_EX); err != nil {
        return err
    }
    defer syscall.Flock(int(f.Fd()), syscall.LOCK_UN)
    // Read existing queue (or empty), call fn, write back, truncate
    ...
}
```

POSIX `flock` works on macOS and Linux. Handles concurrent agent access.

## Output Format

All JSON to stdout. Errors to stderr + exit 1.

**`dtq submit 5 --branch coding-1/auth`**:
```json
{"taskId":"5","stage":"review","message":"submitted for review"}
```

**`dtq claim review`**:
```json
{"taskId":"5","stage":"review","branch":"coding-1/auth","claimedBy":"code-review","cycles":0}
```

**`dtq approve 5`**:
```json
{"taskId":"5","stage":"qa","message":"advanced to qa"}
```

**`dtq reject 5 --reason "missing error handling"`**:
```json
{"taskId":"5","stage":"coding","cycles":1,"message":"sent back for revision"}
```

**`dtq status`** (full queue):
```json
{
  "items": [
    {"taskId":"5","stage":"review","branch":"coding-1/auth","claimedBy":"code-review","cycles":0},
    {"taskId":"7","stage":"coding","branch":"coding-2/api","claimedBy":"","cycles":1}
  ],
  "counts": {"coding":1,"review":1,"qa":0,"merge-ready":0}
}
```

**`dtq status 5`** (single item with history):
```json
{
  "taskId":"5","stage":"review","branch":"coding-1/auth","cycles":0,
  "history":[
    {"action":"submit","agent":"coding-1","at":"2026-02-06T10:00:00Z"},
    {"action":"claim","agent":"code-review","at":"2026-02-06T10:05:00Z"}
  ]
}
```

**Error**:
```json
{"error":"no unclaimed items in stage 'qa'"}
```

## Agent Identification

`dtq` reads the `DTQ_AGENT` environment variable to identify the calling agent. This avoids needing an `--agent` flag on every command.

```bash
export DTQ_AGENT="coding-1"
dtq submit 5 --branch coding-1/auth
```

The SessionStart hook or agent prompt sets this. If unset, `dtq` uses `"unknown"`.

## Integration with Plugin

### How agents call it

```bash
# Coding agent submits
dtq submit 5 --branch coding-1/auth

# Code Review claims next
dtq claim review

# Code Review approves
dtq approve 5

# Or rejects
dtq reject 5 --reason "missing error handling in auth middleware"

# Anyone checks status
dtq status
```

### Build hook (SessionStart)

```bash
#!/bin/bash
DTQ_DIR="${CLAUDE_PLUGIN_ROOT}/tools/dtq"
DTQ_BIN="${DTQ_DIR}/dtq"
if [ ! -f "$DTQ_BIN" ]; then
  cd "$DTQ_DIR" && go build -o dtq . 2>/dev/null
fi
export PATH="${DTQ_DIR}:${PATH}"
```

### .gitignore

Add to plugin `.gitignore`:
```
tools/dtq/dtq
.dtq/
```

## Cycle Escalation

Built into `reject`:
- Increments `cycles` on each rejection
- At cycles >= 3, output includes `"warning":"escalation recommended — 3+ review cycles"`
- Agents/team-lead see this in the JSON output and act accordingly

## Size Estimate

- `main.go`: ~100 lines (arg parsing, dispatch, usage text)
- `queue.go`: ~180 lines (types, state machine, file I/O, locking)
- `queue_test.go`: ~120 lines
- Total: ~400 lines including tests
