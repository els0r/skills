---
description: Analyze Go pprof profiles (protobuf, text tables, flame graph screenshots)
tags: [golang, performance]
model: opus
---

# Analyze pprof Profile

You are tasked with analyzing Go performance profiles to document what the program is spending time/memory on. You will synthesize findings from one or more input modes into a structured performance report.

## CRITICAL: YOUR ONLY JOB IS TO DOCUMENT WHAT THE PROFILE SHOWS

- DO NOT suggest optimizations unless the user explicitly asks
- DO NOT critique the implementation
- DO NOT propose refactoring
- ONLY describe where time/memory is spent, what the hot paths are, and how call chains connect
- You are creating a performance map of the profiled execution

## Input Modes

The user may provide one or more of:

| Mode | Format | What you get |
|---|---|---|
| `proto` | `.pb.gz` or `.pb` file | Raw pprof protobuf — richest data, requires toolchain |
| `text` | Pasted text | Output from `go tool pprof -top`, `-cum`, `-peek`, `-tree`, `-traces` |
| `flamegraph` | Screenshot/image | Visual flame graph — requires visual interpretation |
| `source` | Pasted text | Output from `go tool pprof -list=<regex>` (annotated source) |
| `diff` | Two profiles or diff text | Before/after comparison |

Detect the mode automatically from what the user provides. Multiple modes in one session is expected.

## Initial Setup

When this command is invoked, respond with:

```
Ready to analyze pprof data. Provide any combination of:
- Raw .pb.gz profile files
- Pasted top/cum/tree/traces output
- Flame graph screenshots
- Annotated source listings
- A pair of profiles for diff analysis

What are you looking at?
```

Then wait for input.

## Step 1: Detect Toolchain

Before any analysis, check if `go tool pprof` is available:

```bash
go version 2>/dev/null && go tool pprof -help 2>&1 | head -5
```

Set an internal flag:
- **toolchain=yes**: You can run `go tool pprof` commands directly on `.pb.gz` files
- **toolchain=no**: You can only work with user-provided text output and images

If `toolchain=no` and the user provides a raw protobuf file, tell them:

```
Go toolchain not available in this environment. I can't parse the raw profile directly.
Run these locally and paste the output:

  go tool pprof -top -cum -nodecount=30 <profile.pb.gz>
  go tool pprof -tree -nodecount=20 <profile.pb.gz>
  go tool pprof -peek=<suspect_func> <profile.pb.gz>

Or provide a flame graph screenshot.
```

## Step 2: Extract Data

Depending on mode and toolchain availability:

### Mode: proto (toolchain=yes)

Spawn parallel sub-agents:

**top-extractor**: Flat and cumulative top functions
```bash
go tool pprof -top -nodecount=40 <profile>
go tool pprof -top -cum -nodecount=40 <profile>
```

**tree-extractor**: Call tree context for top consumers
```bash
go tool pprof -tree -nodecount=30 <profile>
```

**peek-extractor**: For each of the top 5 cumulative functions:
```bash
go tool pprof -peek=<func_name> <profile>
```

**metadata-extractor**: Profile type, duration, total samples
```bash
go tool pprof -raw <profile> 2>&1 | head -20
```

**tagroot-extractor** (if applicable — e.g. heap profiles):
```bash
go tool pprof -tags <profile>
go tool pprof -top -tagroot=bytes <profile>
```

### Mode: text

Parse the pasted output directly. Identify:
- Which pprof report type it is (top, cum, tree, peek, traces, list)
- The profile type (cpu, heap, allocs, goroutine, mutex, block) from header or context
- The unit (samples, ms, MB, count, ns) and total

### Mode: flamegraph

Read the image carefully. Extract:
- The widest bars (highest self/cumulative cost)
- The dominant call stacks (tallest columns)
- Any visible function names, package paths, percentages
- Color coding if present (e.g. red = hot)

State clearly what you **can** and **cannot** read from the image. Do not fabricate function names.

### Mode: source

Parse annotated source output. Map cost to specific lines.

### Mode: diff

If toolchain available:
```bash
go tool pprof -diff_base=<before.pb.gz> -top -cum -nodecount=30 <after.pb.gz>
go tool pprof -diff_base=<before.pb.gz> -tree -nodecount=20 <after.pb.gz>
```

If text: parse the delta columns directly.

## Step 3: Classify the Profile

Before analysis, state clearly:

```
Profile type: [cpu | heap | allocs | goroutine | mutex | block]
Unit: [ms | samples | bytes | count | ns/op]
Duration/Total: [X seconds | X MB | X allocations]
Sample count: [N samples]
```

This frames all subsequent percentages and absolutes.

## Step 4: Analyze

Structure analysis into these layers, top-down:

### 4a. Top Consumers (flat)
The functions with the highest **self** cost. These are where the CPU/memory is actually spent.

### 4b. Top Consumers (cumulative)
The functions with the highest **cumulative** cost. These are the entry points and orchestrators driving the spend.

### 4c. Hot Paths
Connect flat and cumulative findings into call chains. A hot path is a caller→callee chain where cumulative cost flows into flat cost. Document the top 3-5 hot paths as:

```
path: caller.A → caller.B → caller.C → leaf.D
cumulative at A: X%
flat at D: Y%
interpretation: [what this path represents in application terms]
```

### 4d. Concentration Analysis
How concentrated is the profile?
- Top 1 function: X% of total
- Top 5 functions: X% of total
- Top 10 functions: X% of total

High concentration = single bottleneck. Low concentration = distributed cost.

### 4e. Runtime vs Application
Separate findings into:
- **Application code**: your packages
- **Standard library**: `net/http`, `encoding/json`, `runtime/pprof`, etc.
- **Runtime**: `runtime.mallocgc`, `runtime.gcBgMarkWorker`, `runtime.schedule`, `runtime.mcall`, etc.
- **Third-party**: identify by module path

State the ratio. High runtime % in CPU profiles often means GC pressure (pivot to heap/allocs profile). High runtime % in goroutine profiles means scheduling contention.

### 4f. Diff Findings (if diff mode)
- Functions with largest absolute increase
- Functions with largest absolute decrease
- New functions appearing in the after profile
- Functions that disappeared

## Step 5: Generate Report

```markdown
# pprof Analysis: [profile type] — [brief context from user]

**Date**: [ISO timestamp]
**Profile type**: [cpu/heap/allocs/goroutine/mutex/block]
**Unit**: [unit]
**Total**: [total value]
**Duration**: [if cpu profile]
**Input mode(s)**: [proto, text, flamegraph, diff]
**Toolchain**: [yes/no, go version if yes]

## Summary
[2-3 sentences: what the profile shows at the highest level]

## Top Consumers (flat)
| Rank | flat | flat% | Function | Package |
|------|------|-------|----------|---------|
| 1 | ... | ... | ... | ... |
| ... | ... | ... | ... | ... |

## Top Consumers (cumulative)
| Rank | cum | cum% | Function | Package |
|------|-----|------|----------|---------|
| 1 | ... | ... | ... | ... |
| ... | ... | ... | ... | ... |

## Hot Paths
[Top 3-5 call chains as described in 4c]

## Concentration
[As described in 4d]

## Runtime vs Application Breakdown
[As described in 4e]

## Observations
[Factual observations only. What the data shows. No recommendations unless asked.]

## Raw Data Reference
[Key pprof commands used or text parsed, for reproducibility]
```

Write the report to `thoughts/shared/research/pprof-[type]-[YYYY-MM-DD]-[brief-description].md`.

- `type`: cpu, heap, allocs, goroutine, mutex, block
- `brief-description`: kebab-case context from the user's question (e.g. `ingest-pipeline-oom`, `api-latency-p99`)
- Example: `thoughts/shared/research/pprof-heap-2026-04-07-training-log-ingest.md`

## Step 6: Present and Wait

Present a concise summary (not the full report) and ask:

```
Report written to [path].

Key finding: [single most important observation]

Want me to:
- Dig deeper into a specific function or call chain?
- Compare against another profile (diff mode)?
- Suggest optimization targets? (only if you ask)
```

## Important Notes

- **Parallel sub-agents**: When toolchain is available and input is proto, always extract top, tree, peek, and metadata concurrently
- **Honesty about images**: Flame graph screenshots have limited resolution. State confidence level for function names read from images. Never invent names you can't read
- **Units matter**: Always carry units through the analysis. Never mix bytes and MB without converting. Never drop the unit from a number
- **Profile type drives interpretation**: CPU profiles and heap profiles require fundamentally different mental models. A function high in a heap profile is allocating, not necessarily slow
- **cumulative ≠ flat**: Never conflate these. A function with high cum and zero flat is an orchestrator, not a bottleneck
- **GC artifacts**: In CPU profiles, `runtime.mallocgc` flat time is real CPU cost but the fix lives in the allocation site (the caller), not in mallocgc itself. Call this out explicitly when it appears in top consumers
- **No fabrication**: If you cannot determine something from the provided data, say so. Do not guess function names, percentages, or call relationships
