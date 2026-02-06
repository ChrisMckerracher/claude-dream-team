---
name: bug
description: "Start a Bug Discovery workflow. Spawns investigators to analyze, theorize, and fix bugs through collaborative investigation."
user-invocable: true
---

# Bug Discovery Workflow

You are starting a Bug Discovery workflow with the Dream Team. Follow these steps precisely.

## Step 1: Understand the Bug

Read the user's bug report carefully. Gather key information:
- What is the expected behavior?
- What is the actual behavior?
- Steps to reproduce (if known)
- Environment details (if relevant)
- When did it start happening? (if known)
- Error messages or logs (if available)

If the report is incomplete, ask clarifying questions using AskUserQuestion.

## Step 2: Theorize Investigation Leads

Based on the bug report, develop 2-4 investigation leads. Each lead is a theory about what might be causing the bug.

Example leads:
- "Lead 1: The database query is returning stale cached data"
- "Lead 2: The API validation is rejecting valid input due to a regex bug"
- "Lead 3: A race condition between the auth middleware and the request handler"

Present the leads to the user if time permits, or proceed with investigation directly.

## Step 3: Spawn Investigators

For each lead, spawn an appropriate agent:
- **Coding Agent** (`dream-team:coding`): For leads requiring code analysis, tracing execution paths, or understanding data flow
- **QA Agent** (`dream-team:qa`): For leads requiring reproduction, testing specific conditions, or validating behavior against specs

Create a team using TeamCreate:
- Team name: `bug-{short-slug}`
- Description: Brief description of the bug

Provide each investigator with:
- The full bug report
- Their specific investigation lead
- Instructions to use spelunk mode for code exploration
- Instructions to challenge other investigators' findings

## Step 4: Facilitate Investigation

Monitor the investigators as they work:
- Let them explore and theorize
- Encourage them to message each other with findings
- If one investigator finds strong evidence, direct others to validate
- If investigators are going in circles, redirect them

## Step 5: Build Consensus

Once investigators have findings:
1. Review each investigator's theory and evidence
2. Look for convergence - do multiple leads point to the same root cause?
3. If consensus: proceed to Step 6
4. If stuck: proceed to Step 5b

### Step 5b: Stuck Protocol
If investigators cannot reach consensus after reasonable effort:
1. Stop the investigation
2. Summarize what was found and what wasn't
3. Present the findings to the user
4. Ask the user for additional context or direction
5. Either restart investigation with new leads or close

## Step 6: Determine Fix Complexity

Assess the fix:

### Lightweight Fix
If the fix is:
- Isolated to 1-2 files
- Clear what needs to change
- Low risk of side effects

Then:
1. Spawn a single Coding Agent to implement the fix
2. Have them write a test that reproduces the bug
3. Implement the fix
4. Verify the test passes
5. Submit for review (Code Review → QA)

### Complex Fix
If the fix is:
- Touches multiple modules
- Requires design changes
- Has potential side effects
- Unclear scope

Then:
1. Inform the user that this requires the full Epic workflow
2. Transition to the `/epic` workflow with the bug fix as the feature
3. The investigation findings become input to the Product and Architect phases

## Step 7: Completion

1. Summarize the root cause and fix
2. Clean up: TeamDelete to remove the team
3. Report to the user
