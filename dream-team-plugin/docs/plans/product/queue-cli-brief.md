---
epic: "Review Queue Tool"
status: implemented
created: 2026-02-06
priority: high
---

# Product Brief: `dtq` — Dream Team Queue CLI

## Problem Statement

The Dream Team review pipeline (Coding -> Code Review -> QA -> Merge) is currently enforced by convention: agents manually set task metadata and send messages. There is no enforcement of valid transitions, no durable queue ordering, and no cycle tracking. A lightweight CLI tool replaces convention with enforcement.

## CLI Subcommands

### `dtq submit <task-id> --branch <branch>`
Coding agent submits work for review. Transitions task to `review` stage.

### `dtq claim <stage>`
Agent claims the next available item in a stage (`review` or `qa`). Returns the item details. LRU ordering: revisions first, then FIFO.

### `dtq approve <task-id>`
Reviewer approves. Advances: `review -> qa` or `qa -> merge-ready`.

### `dtq reject <task-id> --reason <text>`
Reviewer rejects. Returns to `coding`. Increments cycle count.

### `dtq status [task-id]`
Without args: show full queue grouped by stage. With arg: show one item's history.

**That's it. Five subcommands.**

## State Machine

```
coding --submit--> review --approve--> qa --approve--> merge-ready
  ^                  |                  |
  +---reject---------+                  |
  +---reject----------------------------+
```

Valid transitions only:
| From | Action | To |
|------|--------|----|
| `coding` | `submit` | `review` |
| `review` | `approve` | `qa` |
| `review` | `reject` | `coding` |
| `qa` | `approve` | `merge-ready` |
| `qa` | `reject` | `coding` |

Any other transition is an error.

## Priority Rules (for `claim`)

1. **Revisions first** — tasks bounced back from review/QA get priority (they've already waited)
2. **FIFO** — among equal priority, oldest submission wins
3. **Blocking tasks** — tasks that other tasks depend on get priority over non-blockers

## Data Store

Single JSON file at `.dtq/queue.json` in the repo root. Structure:

```json
{
  "items": {
    "5": {
      "taskId": "5",
      "stage": "review",
      "branch": "coding-1/auth",
      "submittedAt": "2026-02-06T10:00:00Z",
      "claimedBy": null,
      "cycles": 0,
      "history": [
        { "action": "submit", "agent": "coding-1", "at": "...", "note": null }
      ]
    }
  }
}
```

## Acceptance Criteria

- [ ] Single Go binary, no runtime dependencies
- [ ] All 5 subcommands work and produce JSON output (for agent consumption)
- [ ] Invalid transitions return non-zero exit code with clear error message
- [ ] `claim` returns oldest revision first, then FIFO
- [ ] `reject` increments cycle count; 3+ cycles prints escalation warning
- [ ] `status` shows queue grouped by stage with counts
- [ ] Queue file is created on first `submit` if it doesn't exist
- [ ] Concurrent access handled with simple file locking

## Out of Scope

- MCP server / tool registration — this is a plain CLI
- Agent messaging — agents still use SendMessage after CLI calls
- Integration with task system metadata — CLI is the source of truth for queue state
- Web dashboard or UI
