---
description: Refactor a skill to follow progressive disclosure — lean entry point, on-demand supporting files.
tags: [skills, refactor, meta]
argument-hint: <path to the skill to refactor>
---

I want you to refactor my SKILL to follow progressive disclosure principles, so the entry point stays lean and supporting material loads only when needed.

Follow these steps:

1. **Find contradictions**: Identify any instructions within the skill that conflict with each other. For each contradiction, ask me which version I want to keep before proceeding.

2. **Identify the essentials for the entry point**: Extract only what belongs in the main skill file (e.g., SKILL.md or the top-level instruction):
   - One-sentence description of what the skill does and when to invoke it
   - Trigger conditions / activation criteria
   - Required inputs or preconditions
   - Core workflow steps at a high level (a short checklist or numbered outline)
   - Pointers (links) to deeper material — not the material itself

3. **Group the rest into on-demand references**: Organize remaining content into logical categories that the agent loads only when relevant to the current step. Examples:
   - Detailed procedures for specific sub-tasks
   - Reference tables, schemas, or specifications
   - Example inputs/outputs
   - Edge cases and troubleshooting
   - Templates or boilerplate

   Create a separate file per category.

4. **Create the file structure**: Output:
   - A minimal entry-point file with links to the supporting files, written so the agent knows when to follow each link (e.g., "If the user provides X, see details/x-handling.md")
   - Each supporting file, self-contained and focused on one concern
   - A suggested folder layout (e.g., `skill-name/SKILL.md`, `skill-name/references/`, `skill-name/examples/`, `skill-name/templates/`)

5. **Flag for deletion**: Identify any instructions that are:
   - Redundant (the agent already knows this from general training)
   - Too vague to be actionable
   - Overly obvious filler
   - Duplicated across sections

Guiding principle: The entry point should be small enough to always load cheaply. Everything else should be reachable in one hop, with clear signposts telling the agent when to follow each link.
