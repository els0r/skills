---
description: Refine a draft prompt for Claude Opus 4.7
tags: [ai, prompt]
argument-hint: <paste the draft prompt>
model: claude-opus-4-7
allowed-tools: []
---

Refine the draft prompt below for Claude Opus 4.7. Return a version
ready to paste into Claude Code or another Opus-backed tool.

## Process

1. Extract intent in one sentence. If the draft supports multiple
   readings, list them and ask — don't guess.

2. Check for three things. Either infer with a labeled assumption, or
   ask:
   - Inputs: data, tools, prior context available to the model
   - Constraints: hard limits, non-negotiables, prohibitions
   - Output: format, length, artifact type, success criteria

3. Replace vague terms ("good", "clean", "concise") with measurable
   criteria or one concrete example.

4. Cut anything that does not change the output: pleasantries, hedges,
   redundant instructions, context padding.

5. For non-trivial constraints, state the *reason*. Opus uses it to
   handle edge cases the author did not anticipate.

6. Specify failure modes: insufficient information, infeasible task,
   conflicting constraints.

## Structure for the refined prompt

- Task first, one to two sentences.
- User-supplied content and bulky inputs in XML tags (`<context>`,
  `<data>`, `<examples>`). Opus treats tag boundaries as semantic
  and won't confuse them with instructions.
- Constraints adjacent to the output spec, not scattered.
- Examples last, varied enough to show the edges.
- For complex tasks, invite reasoning before answering. Do not
  prescribe the steps — Opus picks them better than you will.

## Output

1. The refined prompt, fenced, ready to paste.
2. Changelog: cut / clarified / assumed.
3. Open questions, if any.

## Constraints on your own work

- Metric units only.
- No preamble, no "here is your refined prompt" framing.
- If the draft is already tight, say so and change little.
- If intent is incoherent or constraints contradict, say so and ask
  for a rewrite. Do not paper over it.
- Skip role scaffolding ("You are an expert...") unless the task
  genuinely needs a domain lens. For Opus it is usually noise.

<draft>
$ARGUMENTS
</draft>

