---
name: Git Worktree Management
description: "Use when managing parallel development branches via git worktrees. Provides worktree lifecycle management for coding agents working on isolated tasks, branch naming conventions, and merge-back protocols."
version: 1.0.0
---

# Git Worktree Management

Git worktrees enable multiple coding agents to work on different tasks simultaneously without interfering with each other. Each agent gets its own working directory with its own branch.

## Worktree Lifecycle

```
CREATE → WORK → SUBMIT → REVIEW → QA → MERGE → CLEANUP
```

### 1. Create Worktree

```bash
# From the main repo root
EPIC_BRANCH="epic/feature-name"
AGENT_NAME="coder-1"
TASK_ID="42"
TASK_SLUG="add-user-api"
WORKTREE_DIR="../worktrees/${AGENT_NAME}-task-${TASK_ID}"

# Create worktree from the epic branch
git worktree add "${WORKTREE_DIR}" "${EPIC_BRANCH}"

# Enter worktree and create feature branch
cd "${WORKTREE_DIR}"
git checkout -b "${AGENT_NAME}/${TASK_SLUG}"
```

### 2. Work in Worktree

```bash
# Stay in your worktree directory
cd "${WORKTREE_DIR}"

# Regular development workflow
# ... make changes ...
git add <specific-files>
git commit -m "feat(users): add user creation endpoint"

# Stay up to date with epic branch periodically
git fetch origin
git rebase "${EPIC_BRANCH}"
```

### 3. Submit for Review

```bash
# Ensure tests pass
npm test  # or project-specific command

# Push feature branch
git push -u origin "${AGENT_NAME}/${TASK_SLUG}"

# Update task status (via TaskUpdate tool, not git)
```

### 4. After Merge Approval

```bash
# Merge into epic branch (done by Team Lead or automation)
git checkout "${EPIC_BRANCH}"
git merge --no-ff "${AGENT_NAME}/${TASK_SLUG}"
git push origin "${EPIC_BRANCH}"
```

### 5. Cleanup

```bash
# Remove the worktree
cd /path/to/main/repo
git worktree remove "${WORKTREE_DIR}"

# Delete the feature branch (local and remote)
git branch -d "${AGENT_NAME}/${TASK_SLUG}"
git push origin --delete "${AGENT_NAME}/${TASK_SLUG}"
```

## Branch Naming Convention

```
{agent-name}/{task-slug}

Examples:
  coder-1/add-user-api
  coder-2/fix-auth-middleware
  coder-1/update-payment-types
```

## Worktree Directory Convention

```
project-root/
├── .git/                    # Main repo
├── src/                     # Main working directory
└── ../worktrees/            # Sibling directory for worktrees
    ├── coder-1-task-42/     # Agent 1's workspace
    ├── coder-2-task-43/     # Agent 2's workspace
    └── coder-1-task-44/     # Agent 1's next task
```

## Handling Conflicts

When rebasing on the epic branch produces conflicts:

1. **Simple conflicts**: Resolve in the worktree and continue rebase
2. **Complex conflicts**: Message the other Coding agent whose changes conflict
3. **Design conflicts**: Escalate to Team Lead → Architect for drift resolution

## Worktree Status Check

```bash
# List all active worktrees
git worktree list

# Check worktree health
git worktree list --porcelain
```

## Worktree Assignment

The Team Lead assigns worktree paths when creating tasks. Coding agents should use the assigned path from their task description (e.g. `Worktree: ../worktrees/coder-1-task-42`), not invent their own. This ensures the worktree path is known throughout the pipeline — Code Review and QA agents receive it via handoff messages and dtq.

## Worktree Path in Task Assignment

**CRITICAL**: The Team Lead MUST include `Worktree: ../worktrees/{agent-name}-task-{id}` in every coding task description. This is enforced by a `PreToolUse` hook on `TaskCreate` that blocks coding tasks without worktree paths.

### Path Flow Through Pipeline

The worktree path flows through the entire review pipeline:

```
Team Lead task assignment
  ↓ (includes Worktree: ../worktrees/coder-1-task-42)
Coding Agent reads from task description
  ↓ (passes worktree path to dtq submit)
dtq submit --worktree <path>
  ↓ (stores worktree path in queue item)
dtq claim output
  ↓ (returns worktree path to Code Review/QA)
Code Review/QA handoff messages
  ↓ (includes worktree path for transparency)
Team Lead merge confirmation
```

### Why This Matters

1. **Consistency**: All agents reference the same path — no confusion about where the code lives
2. **Traceability**: The path appears in task descriptions, dtq output, and handoff messages
3. **Automation**: dtq returns the worktree path in `claim` output, so Code Review/QA agents know exactly where to navigate
4. **Hook enforcement**: Missing paths are caught at task creation time, not during execution

### Task Assignment Checklist for Team Lead

Before assigning a coding task, verify the description includes:
- [ ] Task ID and title
- [ ] Acceptance criteria
- [ ] **Worktree path**: `Worktree: ../worktrees/{agent-name}-task-{id}`
- [ ] Base branch for the worktree
- [ ] Reference to design docs (if applicable)

## Rules

- **Always** use the worktree path assigned by the Team Lead
- **Never** work directly on the epic branch from a worktree
- **Always** create a feature branch within the worktree
- **Always** rebase (not merge) to stay current with epic branch
- **Always** run tests before submitting for review
- **Always** clean up worktrees after merge
- **Never** have two agents sharing the same worktree
