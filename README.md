# skills

A pack of [Claude Code](https://docs.claude.com/claude-code) skills and slash commands covering planning, code review, Go-specific style/testing/instrumentation, and multi-PR orchestration. Each item has `tags` in its frontmatter; the tables below index them.

## Install

```sh
./install.sh
```

`install.sh` creates per-item symlinks into `~/.claude/skills/` and `~/.claude/commands/`. It is idempotent and warns on conflicts.

If `~/.claude/skills` or `~/.claude/commands` is a whole-directory symlink (from an earlier install), convert each to a real directory first:

```sh
rm ~/.claude/skills ~/.claude/commands
mkdir ~/.claude/skills ~/.claude/commands
```

## Skills

| Skill | Tags | Description |
|---|---|---|
| [autonomous-orchestration](skills/autonomous-orchestration/) | process, orchestration | Hand off multi-PR coordination across worktrees with PR/CI watching. |
| [codebase-analyzer](skills/codebase-analyzer/) | research | Explains HOW components work with file:line refs; no improvements suggested. |
| [codebase-locator](skills/codebase-locator/) | research | Finds WHERE code lives — files, directories, components. |
| [coding-style](skills/coding-style/) | style | Cross-language engineering principles: structure, clarity, restraint. |
| [design-rubric](skills/design-rubric/) | design, review | Six-criterion rubric for critiquing UI wireframes and layouts. |
| [diagnose](skills/diagnose/) | debugging, process | Reproduce → minimise → hypothesise → instrument → fix loop for hard bugs. |
| [go-instrumentation](skills/go-instrumentation/) | golang, observability | Structured logging, tracing, metrics — library-agnostic principles with `els0r/telemetry` as reference impl. |
| [go-performance](skills/go-performance/) | golang, performance | Allocation, GC pressure, contention, escape analysis, benchmarking. |
| [go-style](skills/go-style/) | golang, style | Go idioms, error handling, interface design (companion to coding-style). |
| [go-testing](skills/go-testing/) | golang, testing | Table-driven tests, testify, fuzzing, race detection conventions. |
| [grill-me](skills/grill-me/) | process, planning | Interview-style stress test of a plan, one branch at a time. |
| [grill-with-docs](skills/grill-with-docs/) | process, planning, docs | Grilling that updates CONTEXT.md and ADRs as decisions land. |
| [improve-go-architecture](skills/improve-go-architecture/) | golang, architecture | Find deepening opportunities in Go packages: deletion test, seam location, shallow-smell catalogue. |
| [to-issues](skills/to-issues/) | process, planning | Convert a plan or PRD into tracer-bullet issues on GitHub. |

## Commands

| Command | Tags | Description |
|---|---|---|
| [analyze-pprof](commands/analyze-pprof.md) | golang, performance | Document what a Go pprof profile shows; no fixes proposed. |
| [create-plan](commands/create-plan.md) | planning, process | Interactive, iterative implementation plan creation. |
| [design-prompt](commands/design-prompt.md) | ai, prompt | Refine a draft prompt for Claude Opus 4.7. |
| [implement-plan](commands/implement-plan.md) | planning, process | Execute an approved plan phase by phase with verification. |
| [refactor-react](commands/refactor-react.md) | react, refactor | Refactor a Vite + Zustand app for SRP, readability, performance. |
| [research-codebase](commands/research-codebase.md) | research | Comprehensive codebase research written to a structured doc. |

## Credits

`grill-me`, `grill-with-docs`, `diagnose`, `to-issues`, and `improve-go-architecture` are adapted from [Matt Pocock's skills](https://github.com/mattpocock/skills) (MIT-licensed).

## License

MIT — see [LICENSE](LICENSE).
