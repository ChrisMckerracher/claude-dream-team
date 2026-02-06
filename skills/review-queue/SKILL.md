---
name: Review Queue Management
description: "Use when managing the code review and QA pipeline. Provides the review queue protocol using the task system for FIFO ordering, status transitions, and handoff patterns between Coding, Code Review, and QA agents."
version: 1.0.0
---

# Review Queue Management

The review queue orchestrates the handoff pipeline between Coding agents, Code Review agent, and QA agent. It uses the built-in task system with status conventions for queue management.

## Queue Flow

```
Coding Agent completes work
  → Sets task metadata: stage=review, reviewer=pending
  → Messages Code Review Agent

Code Review Agent
  → Claims task (sets reviewer=code-review)
  → Reviews code
  → On APPROVED: sets stage=qa, reviewer=pending
  → On NEEDS_WORK: sets stage=coding, messages Coding Agent

QA Agent
  → Claims task (sets reviewer=qa)
  → Validates against specs
  → On PASSED: sets stage=merge-ready
  → On FAILED: sets stage=coding, messages Coding Agent

Team Lead
  → Monitors merge-ready tasks
  → Merges approved work into epic branch
  → Cleans up
```

## Task Status Convention

Use task metadata to track review pipeline stages:

| Stage | Meaning | Owner |
|-------|---------|-------|
| `coding` | Being implemented | Coding Agent |
| `review` | Awaiting code review | Code Review Agent |
| `qa` | Awaiting QA validation | QA Agent |
| `merge-ready` | Approved by both review and QA | Team Lead |
| `revision` | Sent back for changes | Coding Agent |

## Handoff Protocol

### Coding → Code Review
```
1. Coding Agent: TaskUpdate with metadata { stage: "review" }
2. Coding Agent: SendMessage to Code Review Agent:
   "Task #{id} '{title}' is ready for review.
    Branch: {branch-name}
    Files changed: {list}
    Summary: {brief description}"
```

### Code Review → QA (on approval)
```
1. Code Review Agent: TaskUpdate with metadata { stage: "qa" }
2. Code Review Agent: SendMessage to QA Agent:
   "Task #{id} '{title}' passed code review and is ready for QA.
    Branch: {branch-name}
    Feature file: {path or 'none'}"
```

### Code Review → Coding (on rejection)
```
1. Code Review Agent: TaskUpdate with metadata { stage: "revision" }
2. Code Review Agent: SendMessage to Coding Agent:
   "{feedback using the review template}"
```

### QA → Merge (on pass)
```
1. QA Agent: TaskUpdate with metadata { stage: "merge-ready" }
2. QA Agent: SendMessage to Team Lead:
   "Task #{id} '{title}' passed QA. Ready to merge."
```

### QA → Coding (on failure)
```
1. QA Agent: TaskUpdate with metadata { stage: "revision" }
2. QA Agent: SendMessage to Coding Agent:
   "{failure report using the QA template}"
```

## Queue Priority Rules

Process tasks in this order:
1. **Blocking tasks**: Tasks that other tasks depend on
2. **Revision tasks**: Tasks coming back from a failed review/QA (they've already waited)
3. **FIFO**: First in, first out for equal priority

## Cycle Tracking

Track how many review cycles a task has been through:

- After 2 cycles: Add a note to the task about recurring issues
- After 3 cycles: Escalate to Team Lead for intervention
- The Team Lead may:
  - Reassign the task to a different Coding Agent
  - Split the task into smaller pieces
  - Revise the technical design

## Queue Health Monitoring

The Team Lead should periodically check queue health:

```
Check: How many tasks are in each stage?
  - Many in "review" → Code Review Agent may be overloaded
  - Many in "revision" → Quality issues, may need design review
  - Many in "qa" → QA Agent may be overloaded
  - None in "merge-ready" → Pipeline is flowing or blocked early

Action: If any stage is backing up, the Team Lead should:
  - Investigate the bottleneck
  - Consider spawning additional agents
  - Reprioritize the queue
```
