---
name: Architecture Design
description: "Use when creating technical design documents, analyzing system architecture, making ADR-style decisions, or resolving design drift between coding agents. Provides architecture document templates, decision frameworks, and drift resolution patterns."
version: 1.0.0
---

# Architecture Design Skill

## Architecture Decision Record (ADR) Format

When making technical decisions, document them as ADRs:

```markdown
# ADR-{number}: {Title}

## Status
Proposed | Accepted | Deprecated | Superseded

## Context
What is the issue that we're seeing that is motivating this decision?

## Decision
What is the change that we're proposing and/or doing?

## Consequences
What becomes easier or more difficult to do because of this change?

## Alternatives Considered
What other approaches were evaluated and why were they rejected?
```

## Technical Design Checklist

Before submitting a technical design for review:

- [ ] Component boundaries are clearly defined
- [ ] Data flow is documented (inputs, transformations, outputs)
- [ ] API contracts specify request/response schemas
- [ ] Error handling strategy is defined
- [ ] State management approach is documented
- [ ] Dependencies (external services, libraries) are listed
- [ ] Performance considerations are addressed
- [ ] Security implications are assessed
- [ ] Migration strategy (if changing existing code) is defined
- [ ] Task decomposition recommendations are included

## Drift Resolution Protocol

When parallel coding agents diverge from the design:

1. **Identify the drift**: What specifically diverged?
2. **Classify severity**:
   - **Minor**: Naming, file organization (resolve with convention)
   - **Moderate**: Different patterns for same problem (pick one, document why)
   - **Major**: Incompatible approaches (requires design revision)
3. **Write resolution document**:
   ```markdown
   # Drift Resolution: {Description}

   ## Agents Involved
   - Agent A: {approach}
   - Agent B: {approach}

   ## Resolution
   {Which approach wins and why}

   ## Required Changes
   - Agent A: {what to change}
   - Agent B: {what to change}

   ## Design Doc Updates
   {What to add/change in the original design}
   ```
4. **Communicate to all affected agents**
5. **Update the original design doc**

## Spelunk Request Templates

When you need to understand the codebase, request from a Coding agent:

```
# For understanding module boundaries
"Please spelunk --for=architect --focus='module boundary analysis for {area}'"

# For understanding type contracts
"Please spelunk --for=architect --focus='type definitions and interfaces in {area}'"

# For understanding dependencies
"Please spelunk --for=architect --focus='dependency graph for {module}'"
```

## Common Architecture Patterns

Reference these when making design decisions:

| Pattern | When to Use | Trade-offs |
|---------|------------|------------|
| Repository | Data access abstraction | More files, but testable |
| Strategy | Multiple algorithms | Extensible, but indirection |
| Observer | Event-driven communication | Decoupled, but hard to trace |
| Factory | Complex object creation | Flexible, but hidden complexity |
| Adapter | External service integration | Isolated changes, but mapping overhead |
| Middleware | Cross-cutting concerns | Composable, but ordering matters |
