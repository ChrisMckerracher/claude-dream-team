---
name: epic
description: "Start an Epic workflow. Spawns a Dream Team to plan, design, implement, review, and validate a feature end-to-end."
user-invocable: true
---

# Epic Workflow

You are starting an Epic workflow with the Dream Team. Follow these steps precisely.

## Step 1: Understand the Request

Read the user's input carefully. If the request is vague, ask clarifying questions using AskUserQuestion before proceeding:
- What is the desired outcome?
- Who is the target user?
- Are there technical constraints?
- Is there UI/UX work involved?

## Step 2: Set Up the Team

1. Create a team using TeamCreate:
   - Team name: `epic-{short-slug}` (derived from the feature name)
   - Description: Brief description of the epic

2. Create the initial task list using TaskCreate:
   - Task 1: "Product brief and feature files" (assign to Product agent)
   - Task 2: "Technical design document" (assign to Architect agent)
   - Task 3: "Review planning docs" (assign to yourself - Team Lead)
   - If UI work involved: Task 4: "Design system scan and design spec" (assign to UI/UX Designer)

## Step 3: Planning Phase

1. Determine if Product and Architect can work in parallel:
   - **Parallel**: If the epic is well-defined and both can work independently
   - **Sequential**: If Product needs to define scope before Architect can design

2. Spawn agents using the Task tool:
   - Product agent (`dream-team:product`): Provide the user's request and ask for product brief + .feature files
   - Architect agent (`dream-team:architect`): Provide the request and ask for technical design doc
   - Tell both agents to communicate with each other via SendMessage

3. Wait for both to complete. Review their output together.

4. If you have feedback:
   - Send specific notes to the relevant agent via SendMessage
   - Wait for revisions
   - Repeat until satisfied

5. If UI/UX work is involved:
   - Spawn UI/UX Designer agent (`dream-team:ui-ux-designer`)
   - Have them scan the existing codebase for design patterns
   - Have them create design specs for the new UI elements

## Step 4: User Review Gate

Notify the user:
- "The planning phase is complete. Here's a summary of the plan:"
- Present a concise summary of Product brief, Technical design, and Design spec (if applicable)
- Ask the user to review and approve before proceeding
- This is a **blocker** - do not proceed without user approval

## Step 5: Task Decomposition

Once the user approves the plan:
1. Decompose the work into a DAG of bite-sized tasks
2. Each task should have:
   - Clear title and description
   - Acceptance criteria
   - Dependencies (which tasks must complete first)
   - Estimated scope (small/medium/large)
3. Present the task DAG to the user for approval

## Step 6: Execution Phase

1. Spawn execution team:
   - Code Review Agent (`dream-team:code-review`): 1 instance
   - QA Agent (`dream-team:qa`): 1 instance
   - Coding Agent(s) (`dream-team:coding`): 1-3 instances based on parallelizable tasks

2. Assign tasks to Coding agents based on the DAG

3. Monitor the review pipeline:
   - Coding → Code Review → QA → Merge
   - Handle escalations and blockers

## Step 7: Full Validation

After all tasks are merged:
1. Direct the QA agent to run full validation against all .feature files
2. Review any failures
3. Create new tasks for fixes if needed
4. Repeat until all flows pass

## Step 8: Completion

1. Summarize what was accomplished
2. Clean up: TeamDelete to remove the team
3. Report to the user
