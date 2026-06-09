# Dispatching implementation agents

Read this before dispatching any issue. It covers backend selection,
the brief contract, and post-run verification.

## 1. Select the backend

Check whether the project ships a container-enforced dispatch layer —
a marker directory at the repo root (e.g. `.sandcastle/`) with its
own README. Its presence selects the backend.

### Layer present → dispatch through it, not via `Agent`

Each agent runs inside a sandbox (typically Docker, on a bind-mounted
worktree), so the guardrails are container-enforced and the sandbox
is GitHub-credential-free. The orchestrator stays on the host. Read
the layer's README for the concrete invocation, flags, and output
contract — don't assume them. What holds for any such layer:

- It returns a machine-readable result (e.g. a JSON line) naming the
  branch and the commits produced. Any `report`/summary field is the
  agent's claim, not evidence; verify against the commits (§3).
- The sandbox never touches GitHub (§4), so the orchestrator still
  expands the issue into the prompt, pushes the branch, and opens the
  PR (`Closes #N`) from the host.
- The layer may cap concurrency (often one sandbox at a time on
  modest hardware). Check before fanning out; don't assume parallel
  dispatch.

Dispatching via `Agent` when a container layer exists forfeits its
enforcement of the no-force-push / no-hook-skip guardrails and runs
the agent against host credentials it should never see.

### No layer → dispatch with `Agent` (`isolation: "worktree"`)

The guardrails are prompt-enforced only, so the brief must carry them
(§2).

## 2. Briefs must be self-contained

A subagent has zero memory of this session. References like "as we
discussed" or "the D1 decision" are noise to it.

Each `Agent` prompt restates: the issue number and verbatim scope,
the prior decisions and their rationale (e.g. why the narrower scope,
not the original), the branch name and base, the commit-message
convention, the PR-body requirements, and the guardrails from
SKILL.md. Err long.

Under a container layer, the dispatcher typically forwards only the
issue **title and body** plus a standing prompt file — not this
session's context. The layer's standing prompt carries the
guardrails; but any prior decision the agent must honor has to live
in the issue body *before* you dispatch (see
[recovery.md](recovery.md) § Issue-body amendments).

## 3. After the run — verify, then report

A subagent's completion message reports what it *tried* to do. CI
state, file diffs, and PR body are the source of truth.

After a subagent reports "done", verify via `gh` / GitHub MCP: PR
exists, branch matches, files changed match the brief, `Closes #N`
present, CI status. Report to the user from the verified facts, not
the agent's prose.

Under a container layer additionally: parse the layer's result,
verify `git log <branch>` and `git diff <base>...<branch>` against
scope. Treat an empty commit list as a failed run regardless of how
confident the agent's report reads.

## 4. The sandbox cannot reach GitHub

Under a container layer the agent has no `gh` and no token; its work
leaves the container **only as git commits on its branch**. It cannot
push, open a PR, or read the issue itself. The orchestrator does all
GitHub I/O on the host: the layer expands the issue into the prompt,
and after verification (§3) you push the branch and open the PR with
`Closes #N`.
