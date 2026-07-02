---
name: implementation-finder
description: Find similar implementations across local repos and recommend an approach before coding. Use when the user says "suggest implementation", "what's the best approach", "find similar approaches", "what implementation should I go for", asks for an implementation plan from task context, wants comparable functions/repos, wants tradeoffs, or wants open questions discovered from repo search.
---

# Implementation Finder

Take task context, search local code for similar implementations, compare approaches, recommend one, make a concise plan, list open questions, then save a more detailed scout note to Obsidian.

User communication rule: sacrifice grammar for concision. Chat output must be short; Obsidian note can be detailed.

## Shared Rules

Read `../project-memory-common.md` before saving Obsidian scout notes, resolving vault paths, or using project memory source rules.

## Workflow

1. Confirm job/spec and extract implementation facets:
   - If invoked without a clear job/spec description, do not search broadly and do not write any Obsidian scout note.
   - Ask exactly: "What job/spec should I scout similar implementations for? Describe what needs to be built or changed, where it should live if known, what systems/data are involved, and any constraints. More detail is better."
   - If user provides only a repo, function, customer, or project name, ask: "I have the location/project, but not the job spec yet. What needs to be built or changed?"
   - Name concrete capabilities the task needs, e.g. source system, destination system, file type, transfer style, API, database, schedule, transform, auth, archive, validation.
   - Treat these as searchable facets A/B/C/D, not as a fixed checklist.

2. Search progressively:
   - Start in current repo.
   - If not enough signal, search sibling repos under the same parent, especially `azure-*`.
   - If still weak, search configured `<repo-roots>` from `../project-memory-common.md`.
   - Use `rg` and `rg --files` first.
   - Search by function/customer/system names, package/import names, file patterns, domain words, and translated/local-language terms when relevant.
   - Read project docs only when they affect approach. Respect local `AGENTS.md` and relevant `docs/agents/*`.
   - Identify the requested target project/function if it already exists. If it is only scaffold/skeleton/placeholder, report it as `Target scaffold`, not as a similar implementation.

3. Read likely matches deeply:
   - Do not rely only on `rg` snippets for likely matches.
   - Read `index.ts`, schemas/config files, helpers/classes, and docs/readmes when they explain approach.
   - Prefer newer patterns over older ones. Signals: current helper APIs, repo conventions, recent architecture, local docs, cleaner schema usage, fewer deprecated libraries.
   - Keep older matches only if they contain domain-specific knowledge not present in newer code.

4. Score matches:
   - `Strong match`: same or nearly same systems/capabilities.
   - `Partial match`: same pattern for important facets, missing others.
   - `Reference only`: useful detail, but not a candidate approach.
   - Do not use labels like `fallback`, `placeholder`, or `strong fallback` for matches. Use only `Target scaffold`, `Strong match`, `Partial match`, or `Reference only`.
   - Include function/repo name and clickable file links with line refs.

5. Compare approaches:
   - For each relevant approach, give one concise summary sentence.
   - Add one short tradeoff sentence: pros/cons.
   - Mention only approaches that inform the recommendation.

6. Recommend:
   - One sentence: choose approach and why.
   - If recommendation depends on a blocking unknown, say the conditional clearly.
   - For Rantalainen integration repos, do not recommend "no Azure Function needed" merely because a direct vendor/SFTP setup may be possible. Assume production work is represented by an Azure Function project. If code is minimal, say "thin transfer/provisioning-focused function" or "minimal implementation around vendor-generated files".

7. Plan:
   - Domain-specific steps only.
   - Do not list obvious project hygiene as steps, e.g. "add logging", "handle errors", "run build", unless the task specifically hinges on it.
   - Scale plan length to task size. Small task usually 3-5 steps. Medium 5-7. Large only when genuinely broad.

8. Open questions:
   - `Critical open questions`: blocking questions not answerable from task context + repo search.
   - `Nice-to-have open questions`: useful but non-blocking.
   - Do not ask questions whose answer is obvious from the repo or can be handled by conservative default.

9. Save detailed scout to Obsidian:
   - Resolve vault via `../project-memory-common.md`.
   - Folder: `<vault>/<work-root>/Checkpoints/<project-name>/`
   - Filename: `<YYYY-MM-DD> - <repo> - <task-short-title> - implementation scout.md`
   - Create folders if missing. Overwrite the same file if this scout is run again for the same repo/task/date.
   - If save fails or vault unavailable, still return chat output and mention the save failure.
   - Do not include secrets, tokens, passwords, private keys, full env values, or sensitive raw customer data.

## Chat Output Shape

Use this shape unless the user asks otherwise:

```markdown
**Target**
- Target scaffold: `<function/project>` - [file](/abs/path/file.ts:1): <state, e.g. timer scaffold only>.

**Similar Implementations**
- Strong match: `<function/repo>` - [file](/abs/path/file.ts:1): <approach>. Tradeoff: <one sentence>.
- Partial match: `<function/repo>` - [file](/abs/path/file.ts:1): <approach>. Tradeoff: <one sentence>.

**Recommended Approach**
<one sentence>

**Plan**
1. <domain-specific step>
2. <domain-specific step>

**Critical Open Questions**
- <question>

**Nice To Have**
- <question>

Saved detailed scout: `<obsidian path>` / Save failed: `<reason>`
```

Omit empty sections. Keep chat normally under 60 lines.
Omit `Target` if the requested project/function is not already present or is already implemented enough to be compared normally.

## Obsidian Note Shape

Use detailed markdown:

```markdown
---
title: <task short title> implementation scout
date: <YYYY-MM-DD>
type: implementation-scout
memory_type: implementation-scout
status: initial-scout
repo: <repo name>
repo_path: <absolute repo path>
project_name: <project/function/customer name>
source_skill: implementation-finder
source_sessions: []
confidence: high|medium|low
created_at: <ISO timestamp with timezone>
tags:
  - work/checkpoint
  - work/implementation-scout
---

# <Task Short Title> Implementation Scout

## Task Context
<What user wants, important business/system context, constraints.>

## Facets Searched
- <facet/search term groups>

## Search Scope
- <current repo / siblings / all git, why expanded>

## Target Project State
- <requested function/project state if found: scaffold, partial, implemented, not found>

## Similar Implementations
| Score | Repo / Function | Files | Matched Facets | Approach | Tradeoff |
|---|---|---|---|---|---|
| Strong match | <name> | <path links> | <A/B/C> | <summary> | <pros/cons> |

## Recommended Approach
<Recommendation and reasoning.>

## Plan
1. <domain-specific step>

## Critical Open Questions
- <blocking question>

## Nice To Have Open Questions
- <non-blocking question>

## Notes For Future Agent
- <important repo pattern, docs, assumptions, search terms>
```
