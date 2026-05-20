---
name: design-rubric
tags: [design, review]
description: Use when critiquing, reviewing, or refining visual designs, wireframes, or UI layouts — especially for small/medium SPAs. Applies a six-criterion rubric covering visual clutter, information hierarchy, spacing discipline, data-table rendering, add-flow comprehensibility, and affordance placement. Invoke when the user asks to “review”, “critique”, “audit”, or “refine” a wireframe, mockup, or existing screen, or when they ask whether a design is cluttered, balanced, or readable. Do NOT use for generating new designs from scratch — pair with a generative skill (e.g. `design-crit`, `frontend-design`) for that.
---

# Design Rubric

A six-criterion rubric for critiquing UI wireframes and layouts.

Philosophy: **strong opinions held loosely**. Opinionated defaults, explicit escape valves. Every critique must be actionable — never “this is cluttered,” always “X and Y compete for attention; demote one.”

## When this skill applies

Trigger when:

- The user asks to review, critique, audit, or refine a wireframe, mockup, or screen.
- The user shares an image, HTML, or sketch of a UI and asks for feedback.
- The user asks a specific rubric question: “is this cluttered?”, “is the hierarchy working?”, “is the spacing off?”.

Do **not** trigger for:

- Generating new designs from scratch (use `design-crit` or `frontend-design`).
- Pure code review without visual concerns.
- Brand / theming decisions in isolation.

Interop: when used alongside `design-crit`, this skill supplies the evaluation rubric for its facet-review loops. `design-crit` generates variants; this skill grades them.

## The rubric

For every screen reviewed, walk the six criteria in order. Name the concrete element that fails and propose one specific fix. If a criterion passes, say so in one sentence and move on.

### 1. Is the UI free of visual clutter?

Signal-to-noise ratio. Every element — borders, shadows, dividers, decorative icons, backgrounds — must justify its presence.

Common violations:

- Borders AND background fill AND shadow on the same card (pick one).
- Dividers between items that whitespace already separates.
- Icons next to labels where the label alone is unambiguous.
- Stroke weights and colors that don’t map to a hierarchy.

Fix pattern: **remove, don’t add**. If a decorative element can disappear without the user being confused, it should.

### 2. Is the most important information visible clearly?

Exactly one primary focal point per screen (or per major region). Squint test: if you blur your eyes until text is unreadable, can you still identify what this screen is *about*?

Common violations:

- Primary metric rendered at the same size as secondary labels.
- CTA competing with a banner, promo, or announcement.
- Header chrome (logo, nav, breadcrumbs) outweighing page content.

Fix pattern: either enlarge/weight the primary, or demote the competitors (lower contrast, smaller size, pushed below the fold).

### 3. Is spacing consistent and principled?

Three-tier spacing model:

**Macro — golden-ratio modular scale, base 8 px.**
Section gaps, card/container padding, heading-to-body spacing, content column widths, vertical rhythm between major blocks.
Scale: `8, 13, 21, 34, 55, 89` px (8 × 1.618ⁿ, rounded — also Fibonacci).

**Micro — 8-px rhythm.**
Icon padding, line-height offsets, form field internal padding, table cell padding, label-to-input gaps, button internal padding.
Scale: `4, 8, 12, 16, 24` px.

**Interaction targets — hard minimums, non-negotiable.**

- Tap targets: ≥ 44 × 44 px.
- Click targets (pointer): ≥ 24 × 24 px.
- Adjacent tap targets: ≥ 8 px gap.

Conflict resolution: **targets > platform conventions > macro scale > micro rhythm**. Golden ratio is a default, not a religion.

Common violations:

- Arbitrary pixel values (`17 px`, `22 px`) with no scale backing.
- Inconsistent gap between similar items (one pair at 16 px, the next at 20 px).
- Micro-spacing inflated to match the macro scale (creates bloat).

### 4. Are tables rendered so they aren’t a wall of text?

Data-dense views fail hardest here. Check:

- **Alignment:** numerics right-aligned, text left-aligned, timestamps monospace or right-aligned.
- **Row separation:** zebra striping OR row dividers, never both. Neither is fine when rows are tall enough.
- **Column count:** more than 6 visible columns usually requires horizontal scroll or column hiding.
- **Primary column emphasis:** the column that identifies the row (name, date) gets weight; metrics are lighter.
- **Empty state:** what shows when there’s no data? A zero-state must exist.
- **Truncation:** long strings truncate with ellipsis AND expose full value on hover/tap.
- **Sticky header:** if more than ~10 rows visible at once.

Fix pattern: if a table feels like a wall, the first move is usually to right-align numerics and demote secondary columns (lighter color, smaller weight) — not to redesign.

### 5. Is the flow for adding X understandable?

For every create/add flow:

- How many clicks/taps from landing to submitted? State it explicitly.
- Is the entry point (the `+` or Add button) visible without scrolling?
- Does the flow have a clear end state (success confirmation, redirect, new item visible)?
- Can the user cancel/back out without losing work — and is that obvious?
- If multi-step: is progress shown (`step 2 of 4`) or disguised as a single action?

Common violations:

- Add button in an unexpected location (top-right on desktop, bottom-center on mobile — pick one per platform).
- Modal stacked on modal.
- Submit button disabled with no explanation of what’s missing.
- Success state that auto-dismisses before the user can read it.

### 6. Does button placement follow intended use?

Placement rules, in priority order:

1. **Primary action** goes where attention lands after reading. LTR forms: bottom-right. Mobile: thumb-reach zone (bottom third).
1. **Destructive actions** separate from constructive ones. Never put Delete and Save adjacent with equal weight.
1. **Button weight mirrors consequence:** primary filled, secondary outlined, tertiary text-only. **One primary per region.**
1. **Cancel / Back** on the opposite side from the primary, or as a subtle link.

Common violations:

- Two filled primary buttons in the same region.
- Primary action at top of form (user reads down, then scrolls back up to commit).
- Destructive action styled identically to primary.
- “Save” and “Save & Continue” both filled, both same color.

## Critique output format

For each screen, produce exactly this block — nothing more:

```
### <screen name>

1. Clutter — <pass | one-line diagnosis + fix>
2. Hierarchy — <pass | one-line diagnosis + fix>
3. Spacing — <pass | one-line diagnosis + fix>
4. Tables — <pass | N/A | one-line diagnosis + fix>
5. Add-flow — <pass | N/A | one-line diagnosis + fix>
6. Affordance — <pass | one-line diagnosis + fix>

Top fix: <the single change with highest leverage>
```

No filler. No “overall this design is pretty good.” Six lines and the top fix.

## Challenge the premise

When the user’s design intent conflicts with the rubric, the rubric loses — **but call the conflict out explicitly**, don’t pretend-accept.

- Maximalist density (Bloomberg terminal, flight dashboard): criterion 1 relaxes; criterion 2 becomes “is each region’s most important info visible within that region?”
- Deliberate asymmetry as aesthetic statement: criterion 6 relaxes on primary-action location, not on button weight rules.
- Brutalist / raw aesthetic: criterion 3 macro scale relaxes; micro spacing and interaction targets still hold.

If the user hasn’t signaled intent and the design looks unusual, **ask before critiquing**. “Is the off-grid layout intentional, or is this a draft?” saves a wasted pass.

## Anti-patterns in critique itself

- Don’t list every violation — surface the top 1–3 per criterion.
- Don’t critique what you can’t see. If layout depends on interaction state not shown, say so and skip.
- Don’t propose a redesign. Propose the smallest change that fixes the named issue.
- Don’t invent issues to fill criteria. `pass` is a valid answer; use it.
- Don’t soften fixes with hedges (“maybe consider possibly…”). State the fix.
