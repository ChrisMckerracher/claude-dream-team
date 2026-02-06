---
name: Product Management
description: "Use when writing product briefs, defining user stories, creating Gherkin .feature files, defining acceptance criteria, or validating that implementations match product intent. Provides templates and frameworks for product documentation."
version: 1.0.0
---

# Product Management Skill

## User Story Framework

Use the standard format with specific guidance:

```
As a [specific persona - not just "user"],
I want [concrete action - what they do, not what the system does],
So that [measurable outcome - how their life improves].
```

**Good example:**
```
As a project manager with 10+ direct reports,
I want to see a summary dashboard of all team members' task progress,
So that I can identify blockers in our weekly standup without asking each person.
```

**Bad example:**
```
As a user,
I want to see data,
So that I can do things.
```

## Gherkin Feature File Best Practices

### Structure
```gherkin
Feature: [Noun phrase describing the capability]
  [1-2 sentence description of the feature's purpose]

  Background:
    Given [shared preconditions for all scenarios]

  Scenario: [Descriptive name - what happens, not how]
    Given [initial state - be specific]
    When [user action - one action per When]
    Then [observable outcome - what the user sees/experiences]
    And [additional verifiable outcome]

  Scenario Outline: [Parameterized scenario name]
    Given [state with <parameter>]
    When [action with <parameter>]
    Then [outcome with <parameter>]

    Examples:
      | parameter | expected |
      | value1    | result1  |
      | value2    | result2  |
```

### Scenario Coverage Checklist
- [ ] Happy path (primary success flow)
- [ ] Empty state (no data, first-time user)
- [ ] Error state (invalid input, server error)
- [ ] Boundary conditions (max length, zero, negative)
- [ ] Permission/auth variations
- [ ] Concurrent/race conditions (if applicable)

## Product Brief Checklist

Before submitting a brief for review:

- [ ] Problem statement is specific and backed by evidence
- [ ] Target persona is clearly defined
- [ ] Success criteria are measurable
- [ ] User stories cover all personas
- [ ] Acceptance criteria are testable (QA can verify)
- [ ] Out of scope is explicitly stated
- [ ] Open questions are listed (not hidden)
- [ ] Dependencies on other features are noted

## Prioritization Framework

When multiple features or stories need ordering:

| Factor | Weight | Score (1-5) |
|--------|--------|-------------|
| User impact | High | How many users? How painful? |
| Business value | High | Revenue, retention, growth? |
| Technical risk | Medium | How uncertain is the approach? |
| Dependencies | Medium | Does other work depend on this? |
| Effort | Low | How much work? (informational) |

Priority = (Impact * 3) + (Business * 3) + (Risk * 2) + (Dependencies * 2)
Lower effort at same priority = do first.

## Acceptance Criteria Writing Guide

Good acceptance criteria are:
- **Specific**: No ambiguity about what "done" means
- **Testable**: QA can write a test for it
- **Independent**: Each criterion stands alone
- **Complete**: Together they fully define "done"

```
Format:
Given [precondition],
When [action],
Then [expected result].

Example:
Given a user is on the login page,
When they enter an invalid email format and click "Sign In",
Then the email field shows a red border and the message "Please enter a valid email address" appears below it.
```
