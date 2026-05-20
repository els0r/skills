---
name: conventional-commit
tags: [git, process]
description: Create git commits in Conventional Commits style (type(scope): subject) when the repo's recent history already uses that format; otherwise mirror the repo's existing style. Use when the user asks to commit, says "commit this", "make a commit", "git commit", "stage and commit", or hands over a finished change for committing.
---

# Conventional Commit

Compose commit messages that match the repo. If the repo already uses Conventional Commits, follow the spec strictly. If it doesn't, mirror whatever pattern recent commits use — do not unilaterally introduce Conventional Commits to a repo that doesn't use them.

## Process

### 1. Detect the repo's style

Sample recent history (skip merges, which often have generated subjects):

```sh
git log --no-merges -n 30 --pretty=format:'%s'
```

Decide which bucket the repo is in by counting how many subjects match the Conventional Commits subject regex:

```
^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([^)]+\))?!?: .+
```

- **≥70% match** → repo uses Conventional Commits. Apply Phase 3a.
- **≤30% match** → repo does not. Apply Phase 3b (mirror existing style).
- **30–70%** → mixed. Show the user 5 recent subjects and ask which to follow. Don't guess.

While you're in the log, also note:
- **Scopes actually used** (the parenthetical) and which paths they map to. Reuse those — do not invent new scopes.
- **Subject case** (lowercase vs sentence-case after the colon) and **line length**.
- **Whether bodies are used** and how (prose paragraph, bullet list, `Refs #123`, `Co-Authored-By`).

### 2. Stage deliberately

Run `git status --short` and `git diff --stat` to see what's changed.

- Stage only files relevant to the commit being composed. Name them explicitly: `git add path/a path/b`.
- Never `git add -A` or `git add .` blindly — those sweep in `.env`, credentials, build artifacts, and unrelated WIP.
- If there are untracked files that look intentional but unrelated, ask before staging them.
- If the diff spans multiple logical changes, split into multiple commits. One topic per commit.

### 3a. Compose — Conventional Commits

Format:

```
<type>(<scope>): <subject>

<body — optional, blank line above>

<footer — optional, blank line above>
```

**Type** — pick from the change content, not the user's wording:

| type     | when                                                                       |
|----------|----------------------------------------------------------------------------|
| feat     | new user-visible behaviour or capability                                   |
| fix      | bug fix; behaviour now matches what was intended                           |
| docs     | documentation only (README, comments, ADRs)                                |
| style    | formatting, whitespace, missing semicolons — no logic change               |
| refactor | code change that neither fixes a bug nor adds a feature                    |
| perf     | performance improvement, no behaviour change                               |
| test     | adding or correcting tests only                                            |
| build    | build system, dependencies, packaging                                      |
| ci       | CI configuration and scripts                                               |
| chore    | maintenance that doesn't fit above (version bumps, file moves, gitignore)  |
| revert   | reverts a previous commit; body says which                                 |

If a change spans types, the commit is too big — split it.

**Scope** — reuse a scope you saw in `git log`. If the diff touches a single subdirectory or module and that module name appears in past scopes, use it. If no good existing scope fits, omit the scope rather than invent one. Don't use multi-word scopes.

**Subject**:
- Imperative mood (`add`, not `added` or `adds`).
- Lowercase after the colon (unless the repo's history uses sentence case).
- No trailing period.
- ≤72 characters total including type/scope/colon. Hard cap at 100.

**Breaking change**: append `!` after the type/scope (`feat(api)!: drop /v1`) AND add a `BREAKING CHANGE:` footer explaining the migration.

**Body** (only when it adds something the diff doesn't):
- Explain *why*, not *what* — the diff already shows what.
- Wrap at ~72 chars.
- Bullets are fine if the repo's history uses them.
- Skip the body for trivial changes (typo fix, version bump).

**Footer**:
- Issue references: `Refs #123`, `Closes #456` — only if the repo's history does this.
- `Co-Authored-By:` lines if multiple people contributed.

### 3b. Compose — mirror existing style

Look at the 10 most recent non-merge commits. Match:
- Subject capitalisation, length, and tense.
- Whether they include a body, and if so, what shape.
- Whether they reference issues, PRs, or tickets and in what format.

Don't impose Conventional Commits on a repo that doesn't use them. Don't impose any other format either. Match what's there.

### 4. Verify before committing

Show the user:
- The exact `git add` lines you're about to run, with the file list.
- The full commit message (subject + body + footer).

Get explicit approval. Don't commit on assumed consent.

Then commit using a heredoc to preserve formatting:

```sh
git commit -m "$(cat <<'EOF'
<subject line>

<body>

<footer>
EOF
)"
```

Run `git status` afterwards to confirm the commit landed and no surprise files were left.

### 5. If a pre-commit hook fails

The commit did **not** happen. So:
- **Do not `--amend`** — there's nothing to amend onto; `--amend` would rewrite the *previous* commit and silently destroy its message.
- Read the hook output. Fix the underlying issue (formatting, lint, type errors).
- `git add` the fixes.
- Re-run the same `git commit` (new commit, not amend).
- **Never `--no-verify`** unless the user explicitly asks for it. A failing hook is signal, not friction.

## Anti-patterns

- `chore: update files` — type without information content. If you can't write a real subject, you don't understand the change yet.
- `fix: bug` — same problem.
- Mixing types in one commit (`feat(api): add endpoint and refactor handler`). Split.
- Inventing a scope to look thorough (`feat(misc):`, `fix(general):`). Omit the scope.
- Pasting the diff into the body. The diff is already in the commit.
- Referencing the current chat session (`per user request`, `as discussed`). Commit messages are read by people who weren't in the chat.
- `git add -A && git commit -m "wip"`. Both halves are wrong.

## When the user gives you a message

If the user dictates the subject (`commit this as "fix the thing"`), use their wording verbatim — don't reformat it into Conventional Commits even if the repo uses them. They asked for a specific message; respect that. You can ask once whether they want it reformatted; if they decline, leave it.
