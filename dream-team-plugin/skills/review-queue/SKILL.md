---
name: Review Queue Management
description: "Use when managing the code review and QA pipeline. Provides the review queue protocol using the `dtq` CLI for FIFO ordering, state transitions, cycle tracking, and handoff patterns between Coding, Code Review, and QA agents."
version: 2.0.0
---

# Review Queue Management

The review queue orchestrates the handoff pipeline between Coding agents, Code Review agent, and QA agent using the `dtq` CLI tool.

## dtq CLI Reference

```bash
dtq submit <task-id> --branch <branch>   # Coding agent submits for review
dtq claim <stage>                         # Claim next item (review|qa)
dtq approve <task-id>                     # Advance to next stage
dtq reject <task-id> --reason <text>      # Send back for revision
dtq status [task-id]                      # Show queue or item detail
```

Agent identity is set via the `DTQ_AGENT` environment variable.

## Queue Flow

```
Coding Agent completes work
  → dtq submit <task-id> --branch <branch>
  → Messages Code Review Agent

Code Review Agent
  → dtq claim review
  → Reviews code
  → On APPROVED: dtq approve <task-id>  (advances to qa)
  → On NEEDS_WORK: dtq reject <task-id> --reason "..."  (back to coding)

QA Agent
  → dtq claim qa
  → Validates against specs
  → On PASSED: dtq approve <task-id>  (advances to merge-ready)
  → On FAILED: dtq reject <task-id> --reason "..."  (back to coding)

Team Lead
  → dtq status  (monitors queue health)
  → Merges merge-ready items into epic branch
```

## State Machine

```
coding --submit--> review --approve--> qa --approve--> merge-ready
  ^                  |                  |
  +---reject---------+                  |
  +---reject----------------------------+
```

| Stage | Meaning | Owner |
|-------|---------|-------|
| `coding` | Being implemented or revised | Coding Agent |
| `review` | Awaiting code review | Code Review Agent |
| `qa` | Awaiting QA validation | QA Agent |
| `merge-ready` | Approved by both review and QA | Team Lead |

## Handoff Protocol

### Coding → Code Review
```bash
dtq submit <task-id> --branch <branch>
```
Then message the Code Review agent with task summary, files changed, and areas of concern.

### Code Review → QA (on approval)
```bash
dtq approve <task-id>
```
Then message the QA agent that the task is ready for validation.

### Code Review → Coding (on rejection)
```bash
dtq reject <task-id> --reason "summary of required changes"
```
Then message the Coding agent with detailed feedback.

### QA → Merge (on pass)
```bash
dtq approve <task-id>
```
Then message the Team Lead that the task is ready to merge.

### QA → Coding (on failure)
```bash
dtq reject <task-id> --reason "summary of failures"
```
Then message the Coding agent with detailed failure report.

## Claim Priority

`dtq claim` automatically applies priority ordering:
1. **Revisions first** — tasks with cycles > 0 (bounced back from review/QA)
2. **FIFO** — oldest submission wins among equal priority

## Cycle Tracking

The `dtq` CLI tracks review cycles automatically:
- Each `dtq reject` increments the cycle count
- At 3+ cycles, `dtq reject` output includes an escalation warning
- The Team Lead should intervene at 3+ cycles:
  - Reassign the task to a different Coding Agent
  - Split the task into smaller pieces
  - Revise the technical design

## Queue Health Monitoring

Use `dtq status` to check queue health:

```bash
dtq status
# Returns: items list + counts per stage
# {"items":[...],"counts":{"coding":1,"review":2,"qa":0,"merge-ready":1}}
```

- Many in "review" → Code Review Agent may be overloaded
- Many in "coding" with high cycles → Quality issues, may need design review
- Many in "qa" → QA Agent may be overloaded
- Items in "merge-ready" → Team Lead should merge them
