---
name: Team Lead Orchestration
description: "Use when coordinating multi-agent workflows, decomposing epics into task DAGs, managing team composition, or handling escalations. Provides orchestration patterns, team spawning templates, and task decomposition strategies."
version: 1.0.0
---

# Team Lead Orchestration Skill

## Team Spawning Templates

### Epic Planning Team
```
Spawn order:
1. Product Agent - for feature files and briefs
2. Architect Agent - for technical design docs
(These can run in parallel if the epic is well-defined)
```

### Epic Execution Team
```
Spawn order:
1. Code Review Agent (1) - monitors review queue
2. QA Agent (1) - validates against product specs
3. Coding Agent(s) (1-3) - implement tasks in worktrees
Optional:
4. UI/UX Designer (1) - if epic involves UI work
```

### Bug Investigation Team
```
Spawn per-lead:
- Coding Agent OR QA Agent per investigation lead
- Team Lead delegates all investigation — never analyzes code directly
(best judgment based on nature of the lead)
```

## Task Decomposition as DAG

When decomposing an epic into tasks, structure as a Directed Acyclic Graph:

```
Example DAG:
  [DB Schema Migration] ──┐
                          ├──> [API Endpoints] ──┐
  [Type Definitions] ─────┘                      ├──> [Integration Tests]
                                                 │
  [UI Components] ─────> [UI Integration] ───────┘
```

### Decomposition Rules
1. Each task should be < 500 lines of change (target)
2. Tasks that can run in parallel should have no dependency edges
3. Tests should be bundled with their implementation task
4. Integration tests may be a final leaf task - that's acceptable
5. Every task needs clear acceptance criteria
6. Mark which tasks require specific agent types

### Task Metadata Template
```
Task: [Short title]
Depends on: [task IDs]
Agent type: coding | qa | design
Acceptance criteria:
  - [ ] Criterion 1
  - [ ] Criterion 2
Estimated scope: small (<100 LOC) | medium (100-300 LOC) | large (300-500 LOC)
```

## Workflow State Machine

```
PLANNING
  ├── Product + Architect working (parallel or sequential)
  ├── Review docs
  ├── Iterate if needed
  └── Approve → DECOMPOSITION

DECOMPOSITION
  ├── Break into task DAG
  ├── User review (blocker)
  └── Approve → EXECUTION

EXECUTION
  ├── Coding agents implement
  ├── Code Review gates
  ├── QA validation
  ├── Critical error? → PLANNING (partial)
  └── All tasks done → VALIDATION

VALIDATION
  ├── Full feature flow testing
  ├── Broken flows? → EXECUTION (new tasks)
  └── All passing → COMPLETE
```

## Escalation Decision Tree

```
Error from Coding Agent:
  ├── Is it a code bug? → Send back to Coding Agent
  ├── Is it a design issue? → Consult Architect
  ├── Is it a requirements issue? → Consult Product
  ├── Is it a critical architecture flaw? → PAUSE all work
  │     ├── Update docs with Architect + Product
  │     ├── May need to reset task list
  │     └── Resume after docs approved
  └── Is it an environment issue? → Escalate to User
```

## Review Pipeline Flow

Managed via the `dtq` CLI tool:

```
Coding Agent completes task
  → dtq submit <task-id> --branch <branch> --worktree <path>
  → Messages Code Review Agent (include worktree path)

Code Review Agent
  → dtq claim review
  → Reviews code
  → Approved: dtq approve <task-id>  → QA stage
  → Needs work: dtq reject <task-id> --reason "..."  → back to Coding

QA Agent
  → dtq claim qa
  → Validates against specs
  → Passed: dtq approve <task-id>  → merge-ready
  → Failed: dtq reject <task-id> --reason "..."  → back to Coding

Team Lead
  → dtq status  (monitor queue health)
  → Merges merge-ready items into epic branch
```
