---
name: retro-summary
description: Create project-completed Obsidian summaries for older work by finding relevant prior AI agent threads/sessions and the matching source repo. Use when the user asks to retroactively summarize previous projects, says "retro summary", "find previous project threads", or asks to create completed summaries for old projects.
---

# Retro Summary

Recover context from previous AI agent work and save durable project-completed summaries to Obsidian. Use this for projects completed before the user's summary skills existed.

User communication rule: "When reporting/answering to me. Be extremely concise. Sacrifice grammar for the sake of concision."

## Default Output

- Vault: resolve via `references/project-memory-common.md`
- Write using the `project-completed-summary` format.
- Folder: `<vault>/<work-root>/Projects/<project-name>/`
- Filename: `<YYYY-MM-DD> - <project-name> - retro-summary.md`
- Include `retro: true` and source session/thread references in frontmatter when known.

## Shared Rules

Read `references/project-memory-common.md` before searching. Retro summaries depend on source discovery, project identity order, safety rules, and confidence handling.

## Workflow

1. Scope projects:
   - If invoked without a project/work scope, repo, branch, date range, session/thread hint, or explicit `all projects`, do not search broadly and do not write any Obsidian note.
   - Ask exactly: "Which completed project or piece of work should I summarize into Obsidian? Give me at least one clue: project/customer/function name, repo, branch, date range, or session/thread hint."
   - If user provides one project name, process only that project.
   - If user asks for all projects, search broadly but report candidate list before writing many notes.
2. Find matching threads/sessions:
   - Search AI agent session sources from the shared rules.
   - Search exact and fuzzy project terms across every available source in the shared source registry.
   - Treat missing agent-specific stores as absent evidence, not failure.
   - Prefer sessions containing both project name and implementation/repo discussion.
   - Extract only relevant user/assistant messages, tool summaries, file names, decisions, errors, and verification results.
   - Do not dump full transcripts into notes.
3. Find matching repo:
   - Search configured `<repo-roots>` from `references/project-memory-common.md`.
   - Match by function/project folder, file names, branch names, commits, and thread cwd.
   - Capture project/function name, repo name, and absolute repo path.
4. Gather repo facts:
   - Use relevant git history, file paths, and source files to confirm what changed.
   - Prefer exact facts from commits/files over fuzzy transcript memory.
   - If repo or thread evidence conflicts, say so in the note.
   - Assign confidence: `high` when thread and repo evidence agree, `medium` when one side is incomplete, `low` when only fuzzy evidence exists.
   - Ask before writing when confidence is low.
5. Write Obsidian summary:
   - Use the project-completed-summary note shape.
   - Include what was worked on, problems faced/solved, main code logic, decisions, verification, follow-ups, and resume context.
   - Include source session paths or IDs under a `Sources` section.
   - Include `confidence: high|medium|low` in frontmatter.
6. Reply to user:
   - Extremely concise.
   - State note path and any confidence caveat.

## Search Hints

- Session logs are usually JSONL or SQLite-backed. Search before parsing. Use `rg -i "<project-term>" <available-agent-session-roots>` when available; otherwise use `grep`, `find`, or agent-native search.
- Useful terms: project name, customer name, function name, integration system names, repo names, file names, branch names.
- Relevant local repos usually live under configured `<repo-roots>`.

## Completion Gate

Done only when the note exists, source paths/IDs are cited, confidence is recorded, repo facts are checked where available, no raw transcript is pasted, and the final reply includes the saved path plus any confidence caveat.

## Safety

- Only inspect previous sessions when user explicitly asks for retro summaries.
- Do not include secrets, tokens, passwords, private keys, full env values, or sensitive customer data.
- Do not preserve raw transcripts. Summarize relevant facts.
- If evidence is weak, save a clearly marked partial summary only after saying confidence is limited.
