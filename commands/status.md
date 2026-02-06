---
name: status
description: "Check the status of the current Dream Team workflow. Shows task progress, agent assignments, review pipeline state, and any blockers."
user-invocable: true
---

# Dream Team Status Report

Generate a status report of the current Dream Team workflow.

## Step 1: Gather Information

1. Read the current task list using TaskList
2. Check for any active team configuration
3. Review recent task updates and agent messages

## Step 2: Generate Report

Present the status in this format:

```
## Dream Team Status

### Active Workflow
[Epic/Bug/None] - [Name/Description]

### Team Members
| Agent | Status | Current Task |
|-------|--------|-------------|
| Team Lead | active | Coordinating |
| [Agent] | [active/idle] | [Task or "awaiting work"] |

### Task Progress
[X/Y] tasks completed

#### By Stage
- Pending: [count]
- In Progress: [count]
- In Review: [count]
- In QA: [count]
- Merge Ready: [count]
- Completed: [count]

### Review Pipeline
| Task | Stage | Assignee | Cycles |
|------|-------|----------|--------|
| [Task] | [Stage] | [Agent] | [N] |

### Blockers
- [Any blocked tasks or waiting-on-user items]

### Recent Activity
- [Last 3-5 significant events]
```

## Step 3: Highlight Issues

If any issues are detected, call them out:
- Tasks stuck in review for > 2 cycles
- Review queue backing up
- Agents that appear idle with work available
- Tasks blocked on user input
- Critical errors that need attention
