---
epic: "Task Queue Tool"
status: draft
created: 2026-02-06
priority: critical
---

# Product Brief: Task Queue Tool (MCP Server)

## Problem Statement

The Dream Team plugin currently uses a **skill document** (`review-queue/SKILL.md`) to describe the review pipeline protocol. Agents are expected to:

1. Manually call `TaskUpdate` to set metadata fields (`stage`, `reviewer`)
2. Manually call `SendMessage` to notify the next agent in the pipeline
3. Mentally track queue ordering rules (blocking > revision > FIFO)
4. Self-enforce valid stage transitions

This approach is **fragile and error-prone** because:

- **No enforcement**: Nothing prevents an agent from setting `stage: "merge-ready"` directly from `coding`, skipping review entirely
- **No atomicity**: Stage update and notification are separate calls; an agent can update the stage and forget to notify, leaving tasks invisible in the queue
- **No ordering guarantee**: Priority rules (blocking > revision > FIFO) exist only as text guidance; agents must compute ordering themselves every time they pick up work
- **No cycle tracking**: Review cycles are supposed to be counted and escalated after 3 rounds, but no mechanism actually tracks this
- **No health visibility**: The Team Lead has no way to query queue state without manually reading every task's metadata
- **Drift risk**: As agents are context-limited, they may not have the skill loaded when making handoff decisions, causing protocol drift

A **real tool** (MCP server) replaces guidance-with-hope with enforced-by-code. Agents call the tool; the tool handles validation, state transitions, notifications, ordering, and tracking.

## Success Criteria

1. Zero manual `TaskUpdate` metadata calls for pipeline stage management — all transitions go through the queue tool
2. Invalid stage transitions are rejected with a clear error message
3. Agents calling `queue_next` always receive the correctly-prioritized task
4. Review cycles are tracked automatically and escalation fires at the configured threshold
5. Team Lead can query queue health in a single tool call
6. Existing agents (Coding, Code Review, QA, Team Lead) can adopt the tool with minimal prompt changes

## Tool API Surface

### `queue_submit`

Submit a task to the review pipeline.

```
queue_submit(task_id: string, stage: "review" | "qa", summary?: string)
```

- **Who calls it**: Coding Agent (submitting to review), Code Review Agent (advancing to QA)
- **What it does**:
  - Validates the task exists and is in a valid source stage for the target
  - Sets the task stage
  - Records a timestamp for LRU ordering
  - Increments review cycle count if re-entering from revision
  - Sends automatic notification to the agent pool responsible for the target stage
- **Returns**: `{ ok: true, position: number }` — the task's position in the target queue

### `queue_claim`

Claim the next task from a stage queue, or claim a specific task.

```
queue_claim(stage: "review" | "qa", agent_name: string, task_id?: string)
```

- **Who calls it**: Code Review Agent (claiming from review queue), QA Agent (claiming from QA queue)
- **What it does**:
  - If `task_id` is provided, claims that specific task (if it's in the requested stage and unclaimed)
  - If `task_id` is omitted, returns the highest-priority unclaimed task using priority rules (see below)
  - Sets the reviewer to `agent_name`
  - Records claim timestamp
- **Returns**: `{ ok: true, task_id: string, summary: string, cycle: number }` or `{ ok: false, reason: "queue_empty" | "already_claimed" | "invalid_stage" }`

### `queue_advance`

Approve a task and advance it to the next stage.

```
queue_advance(task_id: string, agent_name: string, verdict: "approved", notes?: string)
```

- **Who calls it**: Code Review Agent (review → QA), QA Agent (QA → merge-ready)
- **What it does**:
  - Validates the caller is the current reviewer for this task
  - Advances to the next stage in the pipeline
  - Records approval with optional notes
  - Sends automatic notification to the next stage's agent pool (or Team Lead for merge-ready)
- **Returns**: `{ ok: true, new_stage: string }`

### `queue_reject`

Reject a task and send it back for revision.

```
queue_reject(task_id: string, agent_name: string, reason: string, severity?: "must_fix" | "should_fix")
```

- **Who calls it**: Code Review Agent, QA Agent
- **What it does**:
  - Validates the caller is the current reviewer
  - Sets stage to `revision`
  - Increments the review cycle counter
  - Records the rejection reason and severity
  - Sends automatic notification to the original Coding Agent with the reason
  - If cycle count >= escalation threshold (default 3), auto-notifies Team Lead
- **Returns**: `{ ok: true, cycle: number, escalated: boolean }`

### `queue_query`

Query the current state of the queue.

```
queue_query(stage?: string, task_id?: string)
```

- **Who calls it**: Any agent, but primarily Team Lead
- **What it does**:
  - If `task_id` is given, returns that task's pipeline state (stage, reviewer, cycle count, history)
  - If `stage` is given, returns all tasks in that stage, ordered by priority
  - If neither is given, returns a summary of all stages
- **Returns**: Task details or queue listing

### `queue_health`

Get queue health metrics and bottleneck detection.

```
queue_health()
```

- **Who calls it**: Team Lead
- **What it does**:
  - Counts tasks per stage
  - Calculates average time-in-stage
  - Identifies bottlenecks (stages with disproportionate queue depth)
  - Lists tasks that have exceeded cycle thresholds
  - Reports any unclaimed tasks that have been waiting longer than a configurable threshold
- **Returns**:
  ```
  {
    stages: { review: { count, avg_wait_ms, oldest_task_id }, qa: { ... }, ... },
    bottleneck: "review" | "qa" | null,
    escalations: [{ task_id, cycle, reason }],
    stale_tasks: [{ task_id, stage, waiting_since }]
  }
  ```

## User Stories

### Coding Agent
> As a Coding Agent, I want to submit my completed work to the review queue with a single tool call, so that I don't have to remember the multi-step handoff protocol and can be confident the right reviewer is notified.

> As a Coding Agent, I want to receive automatic notifications when my task is rejected with a clear reason, so that I can address feedback without relying on another agent remembering to message me.

### Code Review Agent
> As a Code Review Agent, I want to claim the highest-priority task from the review queue with a single call, so that I always work on the most important item without manually computing priorities.

> As a Code Review Agent, I want to advance or reject a task with enforced validation, so that I can't accidentally skip stages or forget to track review cycles.

### QA Agent
> As a QA Agent, I want to claim tasks from the QA queue knowing they have already passed code review, so that I'm never validating unreviewed code.

> As a QA Agent, I want to reject a task with structured feedback that automatically notifies the Coding Agent, so that the feedback loop is reliable and traceable.

### Team Lead
> As the Team Lead, I want to see queue health in a single call, so that I can identify bottlenecks and intervene before the pipeline stalls.

> As the Team Lead, I want automatic escalation when a task cycles through review 3+ times, so that I can intervene on quality issues before they waste more cycles.

> As the Team Lead, I want to see the full history of a task's journey through the pipeline, so that I can diagnose process problems and coach agents.

## State Machine

Valid stage transitions (enforced by the tool):

```
                  ┌─────────────────────────┐
                  │                         │
                  ▼                         │
  coding ──► review ──► qa ──► merge-ready  │
               │         │                  │
               │         │                  │
               └──► revision ◄──┘           │
                      │                     │
                      └─────────────────────┘
                    (back to review via submit)
```

| From | To | Trigger | Who |
|------|----|---------|-----|
| `coding` | `review` | `queue_submit(stage: "review")` | Coding Agent |
| `review` | `qa` | `queue_advance(verdict: "approved")` | Code Review Agent |
| `review` | `revision` | `queue_reject(...)` | Code Review Agent |
| `qa` | `merge-ready` | `queue_advance(verdict: "approved")` | QA Agent |
| `qa` | `revision` | `queue_reject(...)` | QA Agent |
| `revision` | `review` | `queue_submit(stage: "review")` | Coding Agent |

Any other transition is **rejected** by the tool with an error explaining the valid options.

## Priority Rules

When `queue_claim` is called without a specific `task_id`, the tool selects the next task using this priority order:

1. **Blocking tasks**: Tasks that have other tasks in their `blocks` list (from the task system). Unblocking these unlocks parallelism for the team.
2. **Revision tasks**: Tasks returning from a rejection cycle. They've already consumed review/QA time; completing them avoids sunk-cost waste. Within revision tasks, higher cycle counts get priority (they're more urgent to resolve).
3. **FIFO**: Among equal-priority tasks, the one submitted earliest (lowest timestamp) is served first.

## Review Cycle Tracking

The tool automatically tracks how many times a task has been through the review pipeline:

| Cycle | Behavior |
|-------|----------|
| 1 | Normal first review |
| 2 | Tool adds a note: "Second review cycle — recurring issues may indicate unclear requirements or design" |
| 3+ | **Auto-escalation**: Team Lead is notified with task history. Recommended interventions: reassign, split task, or revisit design |

Cycle count resets to 0 only when the task reaches `merge-ready`.

## Backing Store

- **Lightweight JSON file**: `~/.claude/teams/{team-name}/queue.json`
- No external dependencies (no Redis, no SQLite)
- Read-on-demand, write-on-mutate pattern
- File locking via atomic write (write to temp, rename) to handle concurrent agent access
- Schema versioned for future migration

## Out of Scope

- **Task creation**: The tool does not create tasks. Tasks are created via the existing `TaskCreate` tool; the queue tool manages their pipeline journey.
- **Task assignment outside the pipeline**: Assignment of coding work is still handled by the Team Lead via `TaskUpdate`. The queue tool only manages the review/QA pipeline.
- **Git operations**: Branch management, worktrees, and merging remain separate concerns.
- **Notification content customization**: The tool sends standardized notifications. Agents can add detail in their own messages after using the tool.
- **Cross-team queues**: The tool operates within a single team's task list. Multi-team coordination is out of scope.
- **UI/Dashboard**: No visual queue dashboard. Queue state is accessed via `queue_query` and `queue_health` tool calls.

## Open Questions

1. **Should `queue_submit` auto-set the task's `owner` field?** Currently, the review-queue skill expects the reviewer to claim ownership. The tool could either pre-assign or leave unowned for claim.
   - **Recommendation**: Leave unowned; let the reviewer `queue_claim` to take ownership. This preserves agent autonomy in work selection.

2. **Should the escalation threshold (3 cycles) be configurable per-team?**
   - **Recommendation**: Yes. Store in `queue.json` config section with a default of 3.

3. **Should the tool integrate with the existing `TaskUpdate` metadata, or use its own separate store?**
   - **Recommendation**: Use its own `queue.json` store as the source of truth, but also write a `pipeline_stage` metadata field to the task for visibility in `TaskList` output. This avoids coupling while maintaining discoverability.
