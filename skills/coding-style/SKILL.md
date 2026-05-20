---
name: coding-style
tags: [style]
description: >
  Use for all code generation, review, and refactoring regardless of language.
  Encodes cross-language engineering principles: structure, clarity, restraint.
  Fires alongside language-specific skills, not instead of them.
---

# Coding Style — Universal Principles

## Structure

- Never nest beyond 2 levels of indentation. Use early returns, guard clauses, `continue`, and extracted functions to flatten control flow. No exceptions. This applies to Go, bash, Python, YAML templating, TypeScript — everything.
- Single responsibility per function. If you need a comment to explain a block, extract it.
- If you use comments, make them start lowercase unless they document a public SDK function
- Group related logic. Separate unrelated logic. Whitespace is structure, not decoration.


## Clarity

- Names describe what, not how. No `doProcess`, no `handleStuff`.
- No abbreviations unless they are domain-standard (`ctx`, `req`, `cfg` are fine; `proc`, `mgr`, `svc` need justification).
- Code reads top-to-bottom without backtracking. Declare close to first use.

## Restraint

- Don't add dependencies without stating why and what alternatives were considered.
- Don't generate code that compiles but silently ignores errors or return values.
- Don't add abstractions for one-time operations. No speculative generality.
- Don't refactor, rename, or "improve" code that wasn't part of the task.
- Don't produce boilerplate explanations of standard library functions or language features.

## Before Writing Code

- Read the existing structure first. Don't guess at layout, conventions, or naming patterns.
- State the approach before implementing. Plan, then execute.
- If multiple approaches exist, present trade-offs. Don't pick silently.
