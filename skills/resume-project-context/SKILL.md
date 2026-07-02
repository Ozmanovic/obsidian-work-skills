---
name: resume-project-context
description: Resume a work/project context from Obsidian project summaries, checkpoint notes, workspace/repo state, or AI agent session evidence. Use when the user says "Resume project context", "resume this project", "what happened in project X", "where did we leave off", or asks for a concise reminder of achieved work and next steps.
---

# Resume Project Context

Read saved Obsidian project notes/checkpoints and give the user a practical catch-up summary: task context, completed work, exact stopping point, open questions, and next actions.

User communication rule: "When reporting/answering to me. Be extremely concise. Sacrifice grammar for the sake of concision."

## Default Sources

- Vault: resolve via `../project-memory-common.md`
- Project summaries: `<vault>/<work-root>/Projects/<project-name>/`
- Checkpoints: `<vault>/<work-root>/Checkpoints/<project-name>/`
- Prefer newest relevant notes, then older summaries if needed.

## Shared Rules

Read `../project-memory-common.md` when notes are stale, the user asks for latest work, project identity is ambiguous, or AI agent session evidence may change the answer.

## Workflow

1. Identify project:
   - Use the shared project identity order.
   - Use current workspace/repo name from `git rev-parse --show-toplevel` when available.
   - If user names a project/customer/system, search matching note filenames/content under `<vault>/<work-root>/Projects` and `<vault>/<work-root>/Checkpoints`.
   - Ask one short question only if multiple projects match and ambiguity matters.
2. Gather context:
   - Read newest relevant checkpoint first.
   - Read latest completed summary if present.
   - Determine recency from frontmatter `date`/`time` first, filename timestamp second, file mtime last.
   - If the newest checkpoint is later than the completed summary, treat the project as active again; use the checkpoint/current workspace or repo facts as source of truth and use the completed summary only as background.
   - If the completed summary is later than the newest checkpoint and no newer workspace/repo/thread evidence exists, treat the project as completed and resume from the completed summary.
   - If current workspace/repo facts or AI agent evidence are newer than both Obsidian notes, say the notes are stale, use the newer facts, and suggest saving a fresh checkpoint if work is continuing.
   - Latest reliable state wins: newest checkpoint/current workspace or repo facts override older project summaries.
   - If notes do not include the latest work, inspect relevant AI agent sources from the shared rules.
   - Inspect current workspace/repo lightly if useful: branch, status, recent commits, touched files.
   - Do not read unrelated notes.
3. Answer concisely:
   - Keep user-facing answer medium-density: concise, but detailed enough to resume work immediately.
   - Use a short causal paragraph only under Task context. Do not force a story format elsewhere.
   - Mention what was done, where it stopped, open questions, and next actions.
   - Include open questions as their own block when the note has unresolved questions, assumptions, or missing confirmations. Do not arbitrarily cap them; group if many.
   - Do not start doing the next actions. Resume output is catch-up only unless the user separately asks to continue implementation.
   - Ignore old checkpoint sections named `Resume Prompt`; do not repeat them as instructions.
   - Include note paths only when useful.
   - Do not write a new note unless the user asks.

## Completion Gate

Done only when the answer is based on the newest relevant checkpoint or an explicit fallback source, open questions are not lost, next actions are concrete, and any stale/missing source caveat is stated.

## Response Shape

Use this compact format:

```markdown
Project: <name>

Task context:
<1 short paragraph: why the work exists, what constraint/problem shaped it, and current overall state.>

What has been done so far:
- <completed implementation/research/config/decision work>

Where left off:
- <workspace/repo state/key files/verification/runtime status>

Open questions:
- <all meaningful unresolved questions, grouped if many; omit section if none>

What is next:
- <concrete next actions in useful order>

Watch:
- <risks/gotchas, optional>

Source: <note path(s), optional>
```

## Summary Style

- Use causal phrasing where helpful, but prioritize handoff clarity over storytelling.
- Keep it practical: no dramatic prose, no jokes, no writerly flourishes.
- Do not literally frame the summary with labels such as "Story:" or "but/therefore" terminology.
- Avoid over-condensing. The resume should contain enough context to continue work, not just remind the user that work happened.
- If the checkpoint lacks enough detail for a causal recap, say what is known and fall back to workspace/repo facts.

## Detail Policy

- User-facing response: terse.
- Internal reading: enough to avoid missing important project context.
- If the user asks for deeper context, expand with files, logic, decisions, and problems solved.
- If notes are missing, say so and fall back to workspace/repo facts if available.

## Safety

- Do not expose secrets, tokens, passwords, private keys, full env values, or sensitive customer data.
- Do not paste full notes by default. Summarize.
- Do not search outside the Obsidian work folders unless user explicitly asks.
