---
name: blast-radius
tags: [experimental, review, audit, process]
description: Produce a risk-ranked audit map of a codebase (especially AI-generated code the user hasn't read), so the human can spend limited reading time where failure hurts most — then get out of the way while they look. Use when the user wants to audit, spot-check, sample, or "finally read" a codebase or feature; says things like "where should I look first", "I haven't read any of this", "is this safe to trust", "fire drill", or "blast radius"; or after any large agent-built change lands. Also use proactively when the user expresses unease about code they've delegated but not verified.
---

# Blast Radius

> **Experimental.** This skill is unproven — the ranking heuristics and the
> hand-off point between agent and human are still being calibrated. Expect the
> phases to change. Report where the map was wrong.

A codebase audit is not a full read. It is a map of where failure concentrates,
followed by the human looking at those places themselves. This skill produces
the map and the scaffolding. **It does not perform the judgment — that is the
human's, by design.** An agent grading its own (or a sibling agent's) output is
the judge-is-the-defendant problem this skill exists to break.

The loop: **Map → Predict → Play → Calibrate.**

## Phase 1 — Map

Explore the codebase (README, entry points, ADRs/CONTEXT docs if present,
directory structure, test layout). Then rank components by **blast radius**,
not by size or complexity:

- **Irreversible actions**: anything that writes, approves, merges, deletes,
  pays, sends, or mutates external state. Highest priority, always.
- **Invariants promised in prose**: every guarantee the README/ADRs claim
  ("X is never auto-approved", "gates run before rules") maps to a specific
  code location. Prose-only guarantees are findings, not features.
- **Parsers and folds feeding decisions**: input parsing whose failure silently
  voids an invariant downstream.
- **Concurrency seams and consent flows**: races on the irreversible path.
- **Decoration**: UI, analytics, packaging, docs generation — wrong here costs
  a bad number, not an incident. Mark explicitly as *skim or skip*.

Deliver the map as a short document with three tiers:

1. **Read carefully** (~10–25% of the code, most of the risk) — file paths,
   what to verify at each, and *why this location* in one line.
2. **Verify adversarially instead of reading** — pure functions and decision
   logic better attacked with hostile inputs than read line-by-line.
3. **Skim or skip** — with the cost-of-being-wrong stated, so skipping is a
   decision, not an omission.

Also flag **thesis violations**: places the codebase contradicts its own stated
principles (e.g., a tool premised on hard gates that relies on developer
discipline for its own checks). These are the highest-value audit findings.

## Phase 2 — Predict

Before the human looks at anything, write down the map's predictions in a
`predictions` section:

- Where problems are most likely (top 3 locations, with expected failure mode).
- Where the code is expected to be boring/clean.

This is not ceremony. If the human later finds problems where the map said
boring, the *map generator's risk model is wrong* — that finding outranks any
individual bug, because every future map inherits the error. Make the
prediction falsifiable or don't write it.

## Phase 3 — Play (the human's part)

Set the human up, then stop:

- For tier 2 items, **generate hostile test scaffolding** — edge inputs the
  original agent plausibly didn't consider: malformed formats, sentinel
  characters in odd positions, pending-vs-failed status ambiguity, regexes
  that over-match, empty/huge inputs. Write the test files; let the human run
  and extend them. At least one test should be *expected to fail* on a known
  bad input — a suite that only confirms is a suite with correlated blind
  spots.
- For tier 1 items, give a reading order and per-file "what would wrongness
  look like here" notes. Do **not** summarize the code's correctness — that
  substitutes the agent's judgment for the calibration the human is trying
  to rebuild. Pointing is allowed; verdicts are not.
- Suggest one **fire drill**: a real (or injected) bug the human debugs
  themselves, timed. The time is their incident-recovery floor.

## Phase 4 — Calibrate

After the human plays, compare findings against the predictions:

- Predicted + found → map model confirmed.
- Not predicted + found → record *why the map missed it*; add the pattern to
  the ranking heuristics for next time (in a `calibration.md` the skill reads
  on future runs, if the repo keeps one).
- Predicted + clean → note it; persistent false alarms are also model error.

Close by scheduling: propose a recurring cadence (e.g., one sampled module or
diff per week, fire drill quarterly). Discretionary verification loses to
backlogs; scheduled verification doesn't. Offer to create the calendar/reminder
entry if such tools are available.

## Hard rules

- Never present metric improvements (duplication %, complexity, coverage) as
  verification. Metrics gate agents; they do not replace the human look —
  metrics visible to an optimizing agent get gamed (Goodhart).
- Never audit-and-conclude in one pass. The skill's output is a map and
  scaffolding, then silence until the human reports back.
- Scale to the codebase: for a small tool this is an evening; if tier 1
  exceeds ~25% of the code, re-rank — the map has failed at its one job.
- If there is no test harness, building a minimal one *is* tier 1.
