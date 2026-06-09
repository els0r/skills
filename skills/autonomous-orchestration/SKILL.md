---
name: autonomous-orchestration
tags: [process, orchestration]
description: |
  Use when the user explicitly hands over multi-PR coordination —
  asking Claude to follow through on a user story, work bundle, or
  backlog scope autonomously over multiple turns. Spans issue
  triage, subagent dispatch in isolated worktrees, PR/CI watching,
  and queueing follow-on issues. Example triggers — "work this
  autonomously", "follow through on this bundle", "orchestrate this
  story", "self-drive #N", "run the backlog from X to Y", "take
  this end-to-end". SKIP for — single-PR work, XS changes, direct
  one-shot edits, code review of an existing diff, bug-fix triage,
  doc tweaks, or any task where the user is steering each step. If
  unsure whether the scope qualifies, do NOT invoke — ask the user
  whether they want autonomous mode before proceeding.
---

# Autonomous orchestration

Operate as an orchestrator across several issues, PRs, and a
long-running session — not as a single-PR contributor.

**Preconditions.**

- The user has explicitly handed over coordination (see SKIP list
  above; when in doubt, ask before invoking).
- If the project has a working agreement / contribution guide
  (sizing, labels, the `Closes #N` convention, worktree practices),
  follow it. This skill adds orchestration behavior on top.

## Mode of operation

Run on a dedicated session branch (e.g.
`claude/autonomous-<purpose>-<id>`). It is a coordination workspace
only: it holds no code commits and never opens its own PR — if the
orchestration itself needs an artifact (script, doc), file an XS PR
for it on its own branch off `main`. Implementation happens on
per-issue feature branches cut from `main`, in isolated worktrees,
dispatched to subagents.

**The loop:**

1. Triage the user story into issues (`gh issue create`), applying
   the project's triage taxonomy (size, priority, component, kind)
   if it has one.
2. Confirm bundle composition with the user before dispatching any
   multi-issue agent ([handover-points.md](handover-points.md)).
3. For each issue, dispatch an implementation agent — read
   [dispatch.md](dispatch.md) first to select the backend (container
   layer vs `Agent` worktree) and build a self-contained brief.
4. Subscribe to the resulting PR via the GitHub MCP server (or
   equivalent) so CI and review events stream back.
5. When the agent reports done, verify against GitHub facts, not its
   summary ([dispatch.md](dispatch.md) § After the run).
6. On merge, queue the next dependent issue. On plan invalidation or
   scope surprises, see [recovery.md](recovery.md).

## Guardrails — never autonomous

Always in force, for the orchestrator and every subagent. Each
requires explicit per-action user authorization; an authorization for
one instance does not generalize. See [dispatch.md](dispatch.md) for
how subagents inherit them.

- **No `git push --force`** without permission; to `main` / release
  branches, even with permission, push back and propose a
  non-destructive alternative.
- **No `git reset --hard`, `git clean -fd`, `git checkout --`** on
  branches with unpushed work or unfamiliar files. Investigate
  unexpected state before deleting it — it may be the user's WIP.
- **No amending pushed commits.** Fix forward with a new commit,
  never `git commit --amend` on a published SHA.
- **No `--no-verify`, `--no-gpg-sign`, or other hook-skip flags.** A
  failing hook is a signal, not an obstacle.
- **No merge, auto-merge, review-request, or PR-close.** The
  orchestrator opens and watches PRs; merging is always the user's
  action.
- **No direct issue close.** Let `Closes #N` in a merged PR do it.
- **No branch / worktree deletion** without asking, however stale
  the branch looks.
- **Implementation branches off `main`**, never off the
  orchestration branch.

If a guardrail blocks progress, stop and ask — it is a handover
point. Never search for a flag that bypasses it.

## When to ask the user

Use `AskUserQuestion` only at the six handover points in
[handover-points.md](handover-points.md): bundle composition, plan
invalidation, trade-offs with no clean default, destructive recovery,
post-merge re-dispatch, and guardrail blocks. Routine progress, CI
greens, and webhook events do **not** require asking. Read that file
before asking — and whenever a system event (webhook, task
notification, session resume) tempts you to act on it as if it were
user input.

## Quick checklist (before dispatching an autonomous bundle)

- [ ] User story decomposed into issues, project triage taxonomy
      applied if any.
- [ ] Bundle composition confirmed with the user.
- [ ] Dispatch backend selected per [dispatch.md](dispatch.md) — the
      project's container layer when present, host `Agent` worktree
      otherwise.
- [ ] Each subagent brief is self-contained (issue verbatim, prior
      decisions, branch/base, commit convention, PR requirements,
      guardrails).
- [ ] Implementation branches cut from `main`, not the orchestration
      branch; isolated worktrees.
- [ ] PRs subscribed via the GitHub MCP server on open.
- [ ] Subagent reports verified via `gh` / GitHub MCP before relaying
      to the user.
- [ ] No guardrail action taken without per-action user OK.
