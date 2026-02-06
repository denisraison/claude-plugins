---
name: code-refactor
description: This skill should be used when the user asks to "refactor this package", "reorganize this code", "split this file", "this code is a mess", "too many files", "simplify this module", "restructure this", or mentions god structs, god components, god classes, package organization, module structure, or code that is hard to navigate. Unlike the code-cleanup skill (which removes dead code and tests), this skill restructures working code for clarity and maintainability.
---

# Code Refactor

Restructure working code that has grown tangled over time. Focused on architectural patterns that emerge as code evolves: mixed concerns, accumulated dependencies, tangled relationships, organic complexity.

This is not a linter. The primary focus is structural problems that require understanding the code's architecture and relationships. Complexity scores and idiomatic pattern violations are useful signals for finding problem areas, but always explain the underlying structural issue, not just the number.

## Workflow

### 1. Determine Scope and Language

Identify what to refactor and the primary language. Scope can be:

- **A package/module**: Analyse all files in the package.
- **A file**: Analyse a single file for internal structure issues.
- **A struct/class/component**: Focus on a specific type and its dependencies.

Detect the language from file extensions, then load the appropriate reference:
- Go: [go.md](references/go.md)
- TypeScript/JavaScript: [typescript.md](references/typescript.md)
- Python: [python.md](references/python.md)

### 2. Analyse Structure

Map the current state before proposing changes. Understand how the code flows:

1. List files in scope and what each one is responsible for.
2. Map dependencies between files (who imports what).
3. Identify the public API surface.
4. Trace the main code paths: where does a request/call enter, what does it touch, where does it exit?
5. Look for the emergent patterns described in the language reference: mixed concerns in one place, things that grew fat over time, tangled dependencies, hidden coupling.

### 3. Report

Present findings as structural observations, not metrics. Use this format:

```
## Refactoring Report

### Mixed Concerns
- **pkg/server.go** mixes HTTP handler routing, request validation, business logic, and database queries. These grew together but should be separate layers.

### Accumulated Dependencies
- **pkg/models.go:App** has become a god struct. Every new feature added a field. It now holds the database, cache, logger, mailer, and 8 service references. Nothing forces a developer to think about which dependencies a function actually needs.

### Tangled Relationships
- **pkg/auth.go** imports **pkg/users.go** which imports **pkg/auth.go** via a shared type. The circular dependency is worked around with an interface, but the real issue is that auth and user management are different concerns living in the same package.

### Hidden Coupling
- **pkg/globals.go** defines package-level state that 6 files depend on implicitly. Changing initialization order breaks things in non-obvious ways.
```

End with: "Found X structural issues. Proposed refactoring plan below."

### 4. Propose Plan

After the report, propose a concrete plan with the target structure:

```
## Proposed Structure

pkg/
├── handler.go       (HTTP handlers, delegates to services)
├── service.go       (business logic, receives dependencies)
├── models.go        (domain types only)
└── internal/
    ├── auth/        (extracted: auth has its own concern)
    └── storage/     (extracted: storage is a separate dependency)

## Steps
1. Extract auth types and middleware into internal/auth/ (breaks the circular dep)
2. Move storage logic into internal/storage/
3. Split server.go by layer: handlers stay, business logic moves to service.go
4. Break App god struct into focused components with explicit dependencies
5. Remove globals.go, wire dependencies in main
```

Each step should describe **why**, not just what. The user needs to understand the reasoning.

### 5. Execute

After the user confirms the plan, apply changes one step at a time:

1. Read the file before every edit.
2. Move code in small, testable increments.
3. Update all imports after each move.
4. Run tests after each step. If tests fail, fix before continuing.
5. Preserve the public API unless the user explicitly approves breaking changes.

## Principles

- Refactoring changes structure, not behavior. Tests must pass after every step.
- Focus on problems that hurt navigation and comprehension, not style preferences.
- Do not refactor and add features at the same time. Finish the refactor first.
- Start simple. A slightly-too-big package is better than a fragmented mess of tiny packages with import cycles.
- Only split when there is a real reason: distinct concerns, reuse across consumers, or enforcing API boundaries.
- Avoid creating `utils`, `common`, `helpers`, or `shared` packages. Redistribute to domain-specific locations.
- Prefer the language and project conventions over personal preference. Read the reference for the language.
