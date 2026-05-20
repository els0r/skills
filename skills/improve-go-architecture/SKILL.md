---
name: improve-go-architecture
tags: [golang, architecture]
description: >
  Find deepening opportunities in a Go codebase, informed by the domain
  language in CONTEXT.md and the decisions in docs/adr/. Use when the user
  wants to improve Go architecture, kill shallow abstractions, consolidate
  tightly-coupled packages, resolve import-cycle pressure, or make a Go
  codebase more testable and AI-navigable. Fires alongside go-style —
  different lens (architecture vs idiom). Hands off to grill-with-docs once
  a candidate is picked.
---

# Improve Go Architecture

Surface architectural friction and propose **deepening opportunities** — refactors that turn shallow modules into deep ones. Target: testability and AI-navigability.

- Companion to `go-style`, which covers idiom-level interface design (how to write an interface). This skill operates at the package level (whether an interface should exist).
- Process step 3 hands off to `grill-with-docs` for the design-tree walk and any CONTEXT.md / ADR updates.

## Glossary

Use these terms exactly. Consistent language is the point — don't drift into "component," "service," "boundary."

- **Module** — any unit with a contract and an implementation: function, type, file, *package*. Not a Go module (`go.mod` unit); say **go-module** when ambiguity threatens.
- **Module Interface** — the full contract a caller depends on: types, invariants, error set, ordering, `ctx` semantics, goroutine and channel ownership, receiver shape, config. **Not the Go `interface` keyword** — that's one adapter mechanism among several.
- **Implementation** — the code behind the contract.
- **Depth** — behaviour-per-contract-surface ratio. **Deep** modules hide a lot behind a small Module Interface. **Shallow** modules expose nearly everything they do.
- **Seam** — where the Module Interface meets callers; the place behaviour can be substituted.
- **Adapter** — a concrete satisfier of the Module Interface at the seam. In Go: a struct method set, a function-typed field, a generic type parameter with a constraint, an `internal/` boundary.
- **Leverage** — what callers receive from depth.
- **Locality** — what maintainers receive from depth: change, bugs, knowledge concentrated.

## Principles

- **Deletion test** — imagine the module gone. If complexity disappears, it was a pass-through. If complexity reappears across N callers, it was earning its keep.
- **The Module Interface is the test surface.**
- **One adapter = hypothetical seam. Two adapters = real seam.** Go corollary below.

This skill is *informed* by the project's domain model. CONTEXT.md gives names to good seams; ADRs record decisions the skill should not re-litigate.

## Process

### 1. Explore

Read CONTEXT.md and any ADRs in the area you're touching first.

Then walk the codebase: use the `Explore` subagent if available (Claude Code); otherwise read `go.mod`, top-level packages, then `internal/`. Don't follow rigid heuristics — note where friction shows up:

- Understanding one concept requires bouncing between many small modules.
- Module Interfaces are nearly as complex as the implementation behind them.
- Pure functions were extracted for testability, but real bugs hide in how they're called (no **locality**).
- Tightly-coupled packages leak across their seams.
- Parts that are untested or hard to test through the current interface.

Apply the deletion test to anything suspected shallow. "Concentrates complexity" is the signal.

### 2. Present candidates

Numbered list. For each:

- **Files / packages** involved.
- **Problem** — the friction.
- **Solution** — plain English; what changes.
- **Benefits** — locality, leverage, and how tests improve.
- **Package layout delta** — exact moves, including any new `internal/` boundary.
- **Interface location** — consumer-side or producer-side, and why.
- **Error contract** — which sentinels/typed errors cross the seam.
- **`ctx` and concurrency** — who owns goroutines and channels post-refactor.

Use CONTEXT.md vocabulary for the domain (`order/`, not `orderhandler/`) and the Glossary above for the architecture.

**ADR conflicts**: only surface a candidate that contradicts an ADR when the friction warrants reopening it. Mark clearly (*"contradicts ADR-0007 — worth reopening because…"*). Don't list every theoretical refactor an ADR forbids.

Do NOT propose interfaces yet. Ask: "Which would you like to explore?"

### 3. Hand off to `grill-with-docs`

Once a candidate is picked, invoke `grill-with-docs` to walk the design tree and persist decisions. That skill owns the rules for updating CONTEXT.md inline, sharpening domain terms, and offering ADRs when a load-bearing rejection lands. Do not duplicate those rules here.

Brief the grilling session with the chosen candidate: the friction, the proposed deepening, and the package-layout delta. Let `grill-with-docs` take it from there.

## Go-specific shallow smells

Run the deletion test against:

- **Producer-defined single-implementer interface.** A `Repository` interface only `PostgresRepository` satisfies. Delete the interface; export the struct. Reintroduce when a second adapter actually exists.
- **Catch-all packages** — `utils`, `helpers`, `common`, `pkg`, `internal/internal`. No contract, only contents.
- **Stdlib rewrappers** (`mylog` over `log/slog`, `myhttp` over `net/http`) adding nothing but renaming. If callers still need the wrapped API's mental model, the Module Interface is not smaller than the implementation.
- **Single-method "Service" structs** forwarding one call. Pure pass-through.
- **`any` / `interface{}` in exported signatures** outside genuinely polymorphic spots. Either a missing type parameter or a missing concrete type.
- **Getters and setters over plain fields.** The field is the interface.
- **Functional options** on a constructor with two options, neither defaulting meaningfully. The options *are* the constructor.
- **Files split by mechanical type** — `handlers.go`, `models.go`, `errors.go` — instead of by concept. Cross-file bouncing to read one feature is the friction signal.

## Go-specific deepening signals

- **Consumer-defined interfaces.** *Accept interfaces, return structs.* Interface declared next to the call site, satisfied implicitly by an existing concrete type → real seam. Declared next to the implementation → usually premature.
- **`internal/` as enforcement.** A package boundary without `internal/` is convention; with `internal/`, compiler-enforced. Deepening often means promoting a subpackage into `internal/<concept>/` so the exported surface shrinks.
- **`context.Context` discipline.** Every Module Interface doing I/O or blocking work takes `ctx` first. Modules storing `ctx` in a struct, or calling `context.Background()` internally to defeat caller cancellation, have a broken contract.
- **Error set as contract.** Sentinel and typed errors crossing a seam *are* part of the Module Interface. `fmt.Errorf("...: %w", err)` preserves it; bare `errors.New(...)` discards it. Callers having to read source to know what to `errors.Is` / `errors.As` against = leaky seam.
- **Goroutine and channel ownership.** Who launches, who closes, who waits. If not visible at the Module Interface, callers will get it wrong. Hidden goroutines started in constructors are an interface lie.
- **Cyclic-import pressure.** `import cycle not allowed` is the compiler telling you the seam is in the wrong place. Extract the shared concept into a third package, or merge the two — don't paper over with an interface.
- **Generics over interfaces.** When the seam is "any type with this shape," a type parameter with a constraint is often deeper: the constraint *is* the interface, with no boxing, no nil traps, full type info at the call site.

## Seam-doubling rule, Go corollary

Base rule: one adapter = hypothetical seam; two = real. In Go, **where the interface is declared** decides whether one-impl is premature:

- **Consumer-side, one impl** — fine. Anticipated for tests; the interface stays minimal because it lists only what the caller uses.
- **Producer-side, one impl** — premature. Delete it. If a test needs a fake, define the interface in the test package.
- **Producer-side, two-plus impls** — legitimate, but check size. A `Storer` with 14 methods is two shallow modules in a trenchcoat.

## Testing strategy as a depth signal

The Module Interface is the test surface. For Go:

- Prefer `package foo_test` (external test package). If a test only compiles as `package foo` because it needs unexported helpers, the interface is leaking.
- Prefer fakes (concrete in-memory types) over generated mocks. A mock-heavy test surface is the seam-doubling rule failing: every method had to be mocked because no second real adapter exists.
- `testcontainers`, `httptest`, `t.TempDir` exist so the real dependency *is* the test surface. Reach for an interface only when the real thing is unavailable or unbearably slow.
