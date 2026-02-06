---
name: Implementation & TDD
description: "Use when implementing features, writing tests, setting up git worktrees, or following TDD workflows. Provides implementation patterns, TDD cycle guidance, worktree management, and merge request submission protocols."
version: 1.0.0
---

# Implementation & TDD Skill

## TDD Cycle

### Red-Green-Refactor
```
1. RED: Write a failing test that defines the desired behavior
2. GREEN: Write the minimum code to make the test pass
3. REFACTOR: Clean up the code while keeping tests green
4. REPEAT
```

### When to Use TDD
- **Always TDD**: Business logic, data transformations, validation rules
- **Sometimes TDD**: UI components (test behavior, not layout), API handlers
- **Skip TDD**: Config files, type definitions, simple glue code

### Test-First Template
```typescript
describe('[Feature/Function name]', () => {
  it('should [expected behavior] when [condition]', () => {
    // Arrange
    const input = /* setup */;

    // Act
    const result = functionUnderTest(input);

    // Assert
    expect(result).toBe(/* expected */);
  });

  it('should [error behavior] when [error condition]', () => {
    // Arrange & Act & Assert
    expect(() => functionUnderTest(badInput)).toThrow(/* expected error */);
  });
});
```

## Git Worktree Workflow

### Setup
```bash
# From the epic branch, create a worktree for your task
git worktree add ../worktrees/${AGENT_NAME}-task-${TASK_ID} ${EPIC_BRANCH}

# Move into your worktree
cd ../worktrees/${AGENT_NAME}-task-${TASK_ID}

# Create your feature branch
git checkout -b ${AGENT_NAME}/task-${TASK_ID}-${TASK_SLUG}
```

### During Work
```bash
# Regular commits as you work
git add <specific-files>
git commit -m "feat(scope): description of change"

# Keep up to date with epic branch
git fetch origin
git rebase ${EPIC_BRANCH}
```

### Submitting for Review
```bash
# Ensure tests pass
npm test  # or project-specific test command

# Push your branch
git push -u origin ${AGENT_NAME}/task-${TASK_ID}-${TASK_SLUG}
```

### Cleanup After Merge
```bash
# After QA approval and merge
cd ..
git worktree remove worktrees/${AGENT_NAME}-task-${TASK_ID}
git branch -d ${AGENT_NAME}/task-${TASK_ID}-${TASK_SLUG}
```

## Commit Message Convention

```
type(scope): brief description

[optional body with more detail]

[optional footer]
```

Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `perf`

## Implementation Checklist

Before submitting for review:

- [ ] All acceptance criteria from the task are met
- [ ] Tests pass locally
- [ ] No linting errors
- [ ] No TypeScript/type errors (if applicable)
- [ ] No hardcoded values that should be configurable
- [ ] No console.log or debug statements left in
- [ ] Error handling is appropriate
- [ ] Code follows project conventions (check style guide)

## Merge Request Description Template

When notifying the Code Review agent:

```markdown
## MR: [Task ID] - [Title]

### Changes
- [File 1]: [What changed and why]
- [File 2]: [What changed and why]

### Test Coverage
- [Test 1]: [What it validates]
- [Test 2]: [What it validates]

### Areas of Concern
- [Any tricky logic or uncertainty]

### How to Review
1. Start with [file] for context
2. Then review [file] for the core logic
3. Check tests in [file]
```
