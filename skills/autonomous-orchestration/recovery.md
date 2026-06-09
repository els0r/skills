# Recovery — when a dispatched plan breaks mid-flight

Read this when a subagent's findings invalidate part of the plan, or
when an issue's scope must be narrowed after dispatch.

## Bundled agents may discover plan-invalidating constraints

Verifying a multi-issue bundle against the live framework version can
expose contract or behavior surprises that invalidate part of the
plan. The bundled PR may already be partly correct.

Don't abandon the bundle:

1. Land the safe half if it stands alone.
2. Amend the unsafe half's issue down to a narrower scope (a D1/D2
   split), preserving the original plan inside the issue body (see
   below).
3. Ask the user to pick the narrower scope before re-dispatching —
   this is a handover point
   ([handover-points.md](handover-points.md)).

## Issue-body amendments preserve history

When narrowing scope mid-flight, do not silently overwrite the
original plan — future readers and reviewers need the audit trail.
This also matters under a container dispatch layer, where the issue
body is the *only* context the agent receives
([dispatch.md](dispatch.md) §2), so every decision it must honor has
to be written into the body before re-dispatch.

Format:

1. Prepend a dated `**Edit (post-bundle attempt):**` block with the
   new decision.
2. Rewrite the Scope/Acceptance sections to the new outcome.
3. Append the original plan verbatim under
   `## Original (superseded) plan`.
