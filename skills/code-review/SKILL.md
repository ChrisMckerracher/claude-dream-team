---
name: Code Review
description: "Use when reviewing code changes, enforcing style conventions, checking for security issues, or providing structured feedback. Provides review checklists, feedback templates, and common issue patterns."
version: 1.0.0
---

# Code Review Skill

## Review Checklist

### Correctness
- [ ] Code does what the task description requires
- [ ] Edge cases are handled (null, empty, boundary values)
- [ ] Error handling is appropriate (not swallowed, not over-caught)
- [ ] Async operations handle failures and cancellation
- [ ] State mutations are intentional and controlled

### Code Quality
- [ ] Follows project naming conventions
- [ ] Functions are focused (single responsibility)
- [ ] No dead code, commented-out blocks, or TODO hacks
- [ ] DRY violations are intentional, not accidental
- [ ] Complexity is justified (no over-engineering)
- [ ] Imports are clean (no unused, no circular)

### Security (OWASP Quick Check)
- [ ] No SQL/NoSQL injection vectors
- [ ] No XSS vectors (user input rendered as HTML)
- [ ] No command injection (user input in shell commands)
- [ ] No hardcoded secrets, tokens, or credentials
- [ ] Input validation at system boundaries
- [ ] Authentication/authorization checks present where needed
- [ ] Sensitive data not logged or exposed in errors

### Testing
- [ ] Tests exist for new/changed functionality
- [ ] Tests assert meaningful behavior (not just "doesn't crash")
- [ ] Test names describe what is being tested
- [ ] No test pollution (tests are independent)
- [ ] Both happy path and error cases covered

### Performance
- [ ] No N+1 query patterns
- [ ] No unbounded loops or recursion
- [ ] No blocking I/O in async contexts
- [ ] Reasonable memory usage (no large unnecessary copies)
- [ ] Pagination/limits for list operations

## Feedback Template

```markdown
## Code Review: [Task ID] - [Title]

### Summary
[1-2 sentence overall assessment]

### Must Fix
Issues that block approval:

1. **[file:line]** - [Issue description]
   Suggestion: [How to fix]

### Should Fix
Issues that should be addressed:

1. **[file:line]** - [Issue description]
   Suggestion: [How to fix]

### Nits
Optional improvements:

1. **[file:line]** - [Suggestion]

### Positive Notes
[What was done well - always include at least one]

### Verdict
[ ] Approved
[ ] Approved with nits
[ ] Changes requested (see Must Fix)
[ ] Needs discussion (see below)
```

## Common Issue Patterns

### Anti-Patterns to Flag
| Pattern | Why It's Bad | Suggestion |
|---------|-------------|------------|
| God function (>50 lines) | Hard to test and understand | Extract focused helpers |
| Boolean parameter | Unclear at call site | Use named options or separate functions |
| Nested callbacks (>2 deep) | Callback hell | Use async/await or composition |
| Magic numbers | Unclear meaning | Extract named constants |
| Catch-all error handler | Hides bugs | Catch specific errors |
| Mutable shared state | Race conditions | Use immutable patterns or locks |
| String concatenation for SQL | Injection risk | Use parameterized queries |

### When to Escalate
- Architecture pattern violations → Team Lead
- Conflicting approaches between agents → Team Lead → Architect
- Security vulnerabilities in existing code → Team Lead
- Scope creep (change does more than the task) → Team Lead
- > 3 review cycles on the same task → Team Lead
