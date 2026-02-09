---
name: Review Queue Management
description: "Use when managing the code review and QA pipeline. Provides the review queue protocol using the `dtq` CLI for FIFO ordering, state transitions, cycle tracking, and handoff patterns between Coding, Code Review, and QA agents."
version: 2.0.0
---

# Review Queue Management

The review queue orchestrates the handoff pipeline between Coding agents, Code Review agent, and QA agent using the `dtq` CLI tool.

## dtq CLI Reference

```bash
dtq submit <task-id> --branch <branch> --worktree <path>   # Coding agent submits for review
dtq claim <stage>                         # Claim next item (review|qa)
dtq approve <task-id>                     # Advance to next stage
dtq reject <task-id> --reason <text>      # Send back for revision
dtq status [task-id]                      # Show queue or item detail
```

Agent identity is set via the `DTQ_AGENT` environment variable.

## Queue Flow (Distributed Peer-to-Peer)

Each task flows independently through the pipeline as soon as it's submitted. Tasks don't wait for batch processing — they progress `coding → review → qa → merge-ready` in parallel.

```
Coding Agent completes work
  → dtq submit <task-id> --branch <branch> --worktree <path>
  → Sends ping via SendMessage to Code Review Agent

Code Review Agent (ping-reactive)
  → Receives ping from Coding Agent
  → dtq claim review  (claims the submitted item)
  → Reviews code
  → On APPROVED:
      dtq approve <task-id>  (advances to qa)
      Sends ping via SendMessage to QA Agent
  → On NEEDS_WORK:
      dtq reject <task-id> --reason "..."  (back to coding)
      Sends feedback via SendMessage to Coding Agent

QA Agent (ping-reactive)
  → Receives ping from Code Review Agent
  → dtq claim qa  (claims the approved item)
  → Validates against specs or auto-approves if trivial
  → On PASSED:
      dtq approve <task-id>  (advances to merge-ready)
      Sends merge-ready ping via SendMessage to Team Lead
  → On FAILED:
      dtq reject <task-id> --reason "..."  (back to coding)
      Sends failure report via SendMessage to Coding Agent

Team Lead (merge coordinator)
  → Receives merge-ready pings from QA
  → Merges branch into epic branch
  → Confirms merge via SendMessage to Coding Agent
  → Coding Agent marks TaskList task as completed
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
dtq submit <task-id> --branch <branch> --worktree <path>
```
Then message the Code Review agent with task summary, branch, worktree path, files changed, and areas of concern.

### Code Review → QA (on approval)
```bash
dtq approve <task-id>
```
Then message the QA agent that the task is ready for validation, including the worktree path.

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

## Distributed Handoff Protocol

The pipeline operates peer-to-peer. Agents communicate directly via `SendMessage` to hand off work — the Team Lead is NOT a relay hub for routine handoffs.

### Ping-Reactive Claiming

Code Review and QA agents operate reactively:
- **Wait for a ping** from the upstream agent (Coding → Code Review, Code Review → QA)
- **Claim from dtq** when pinged
- **Do NOT poll** proactively (`dtq claim` without a ping wastes API turns)

If `dtq claim` fails with "no unclaimed items," another agent claimed it first — this is benign, just wait for the next ping.

### Message Routing Rules

| Sender | Event | Recipient |
|--------|-------|-----------|
| Coding Agent | Ready for review | Code Review (NOT Team Lead) |
| Code Review | Passed review | QA (NOT Team Lead) |
| Code Review | Needs revision | Coding Agent |
| QA | Merge-ready | Team Lead |
| QA | Failed validation | Coding Agent |

**Escalations**: Prefix message content with `ESCALATION:` when reporting blockers or design issues to Team Lead.

### Submit-Before-Ping Rule

Coding agents MUST run `dtq submit` before sending the "ready for review" ping. This ensures the item exists in the queue when Code Review attempts to claim it.

## Task Completion Gate

Coding agents must NOT mark their TaskList task as `completed` until the Team Lead confirms the merge. The task stays `in_progress` throughout the entire pipeline (coding → review → qa → merge).

**Completion flow:**
1. QA approves → item enters `merge-ready` stage in dtq
2. QA pings Team Lead
3. Team Lead merges the branch
4. Team Lead pings Coding Agent: "Task {id} merged, mark it completed"
5. Coding Agent marks TaskList task as `completed`

**Hook enforcement**: A `PreToolUse` hook on `TaskUpdate` verifies `dtq status <task-id>` shows `merge-ready` before allowing `status: completed`. This prevents premature completion.

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
