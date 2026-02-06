---
name: Spelunking - Codebase Exploration
description: "Use when exploring a codebase to generate persistent documentation for other agents. Provides the spelunk system for LSP-first code analysis, hash-based staleness tracking, and lens-targeted exploration that produces reusable docs."
version: 1.0.0
---

# Spelunking - Persistent Codebase Exploration

Spelunking is a system for deep, targeted codebase exploration that produces persistent, reusable documentation. Instead of each agent re-reading the same files, spelunk docs are generated once and reused until the underlying code changes.

## Core Concept

```
Agent needs to understand code area
  → Check if spelunk doc exists for that area
    → If YES and FRESH: read the doc, skip exploration
    → If YES and STALE: re-explore, update the doc
    → If NO: explore, create the doc
```

## Document Storage

```
docs/spelunk/
  ├── contracts/          # Type definitions, API signatures (for Architect, QA)
  ├── flows/              # User flows, entry points (for Product)
  ├── boundaries/         # Module edges, dependencies (for Architect)
  ├── trust-zones/        # Auth boundaries, data flow (for Security)
  ├── _index.md           # Human-readable navigation index
  └── _staleness.json     # Machine-readable staleness tracking
```

## Hash-Based Staleness Tracking

Each spelunk document tracks the source files it was generated from:

```json
// docs/spelunk/_staleness.json
{
  "docs/spelunk/flows/user-authentication.md": {
    "generated": "2025-01-10T14:30:00Z",
    "source_files": {
      "src/auth/login.ts": "a1b2c3d4",
      "src/auth/middleware.ts": "e5f6g7h8",
      "src/routes/auth.ts": "i9j0k1l2"
    }
  }
}
```

### Staleness Check Algorithm
```
1. Read _staleness.json entry for the target doc
2. For each source file:
   a. Compute current hash: first 8 chars of SHA-256
   b. Compare with stored hash
3. If ANY hash differs → STALE
4. If all hashes match → FRESH
5. If no entry exists → MISSING (needs full exploration)
```

### Computing File Hash
```bash
# First 8 characters of SHA-256
sha256sum src/auth/login.ts | cut -c1-8
```

## Spelunk Command Syntax

```
spelunk --for=<agent-type> --focus="<area description>"

Options:
  --for       Target agent lens: architect, product, qa, security
  --focus     Natural language description of exploration area
  --check     Only check staleness, don't re-explore
  --force     Re-explore even if FRESH
```

## Lens-to-Content Mapping

| Lens | `--for` | What to Document |
|------|---------|-----------------|
| `contracts/` | architect, qa | Type definitions, interface signatures, API request/response shapes, validation schemas |
| `flows/` | product | User-facing entry points, request flows, state transitions, UI interaction paths |
| `boundaries/` | architect | Module import/export maps, dependency directions, coupling analysis |
| `trust-zones/` | security | Auth checks, data sanitization points, privilege boundaries |

## Document Format

```markdown
---
lens: contracts
focus: "payment processing"
generated: 2025-01-10T14:30:00Z
source_files:
  - path: src/payments/types.ts
    hash: a1b2c3d4
  - path: src/payments/handler.ts
    hash: e5f6g7h8
tool_chain: lsp
---

# Payment Processing - Contracts

## Summary
Brief overview of the payment processing contracts.

## Type Definitions
List key types and interfaces.

## API Signatures
Function signatures with parameter and return types.

## Validation Rules
Input validation and business rule constraints.

## Key Files
- `src/payments/types.ts` - Core payment types
- `src/payments/handler.ts` - Payment processing logic
```

## LSP-First Tool Strategy

Always prefer the fastest available tool:

1. **LSP** (if available): `go_to_definition`, `find_references`, `document_symbols`
   - 900x faster than grep for type/reference lookups
   - Use for: finding implementations, tracing call chains, understanding types

2. **AST tools** (fallback): `ast-grep`, `semgrep`
   - Pattern-based structural search
   - Use for: finding specific code patterns across files

3. **Grep/Glob** (last resort): text-based search
   - Use for: string literals, comments, non-code files

### LSP Availability Check
Attempt an LSP call first. If it fails, fall back to the next tier. Don't waste time checking availability - just try and fallback.

## Pre-Spelunk Doc Check (Standard Protocol)

Before exploring any code area:

```
1. Does docs/spelunk/{lens}/{focus-slug}.md exist?
   → NO: Proceed with full exploration
   → YES: Continue to step 2

2. Run staleness check:
   → Read _staleness.json entry
   → Compare file hashes

3. Is it FRESH?
   → YES: Read the doc directly, skip exploration
   → NO (STALE): Re-explore, update the doc

4. After exploration:
   → Write/update the spelunk doc
   → Update _staleness.json
   → Update _index.md
```

## File Naming Convention

- Use kebab-case slugs derived from the `--focus` parameter
- Max 50 characters, truncated with hash suffix if longer
- Example: `--focus="user authentication flow"` → `user-authentication-flow.md`
- Example: `--focus="very long description of a complex module interaction pattern"` → `very-long-description-of-a-complex-modul-a3b4c5.md`
