---
name: project-completed-summary
description: Save a completed work/project summary to the user's Obsidian vault from current work, workspace/repo state, or AI agent session evidence. Use when the user says "Save project summary to Obsidian", "save completed project summary", "project completed summary", or asks to preserve what happened in a finished AI agent work thread.
---

# Project Completed Summary

Create a durable Obsidian note that lets the user recover project/work context months later. Optimize for practical memory: what changed, why, problems solved, important logic/details, risks, and how to resume if work continues later.

## Default Output

- Vault: resolve via `../project-memory-common.md`
- Folder: `<vault>/<work-root>/Projects/<project-name>/`
- Filename: `<YYYY-MM-DD> - <short-project-title>.md`
- Create folders if missing.
- Use Obsidian Markdown: frontmatter, wikilinks where useful, concise headings, and tags.
- Always record the source workspace/repo name and absolute path when known.

## Shared Rules

Read `../project-memory-common.md` when current visible thread is incomplete, project identity is unclear, or AI agent session evidence may contain the completed work.

## Workflow

1. Identify the project:
   - Use the shared project identity order.
   - Use the project/workstream/deliverable name as the Obsidian folder name when available.
   - Use the current workspace/repo name from `git rev-parse --show-toplevel` for metadata when available.
   - Also capture the absolute workspace/repo path, branch, and source thread/session identifier when known.
   - Derive a short title from the user request, branch name, commits, or thread context.
   - If project identity is genuinely unclear, ask one short question.
2. Gather context:
   - Use the visible/current thread first. Extract user goals, decisions, blockers, fixes, and final outcome.
   - If the visible thread is incomplete, inspect relevant AI agent sources from the shared rules.
   - Inspect workspace/repo facts when useful: `git status --short`, `git branch --show-current`, `git log --oneline -n 10`, `git diff --stat`, `git diff --name-only`.
   - If changes are committed, summarize recent relevant commits. If uncommitted, summarize the diff and touched files.
   - Read only directly relevant files needed to explain the work.
3. Write a memory-focused summary:
   - Prefer specific facts over generic description.
   - Include enough detail that another agent can understand the work later without rereading the whole thread or diff.
   - Preserve important business rules, API/data details, mappings, validation rules, file formats, edge cases, decisions, and customer-specific quirks.
4. Save the note to Obsidian and report the path.

## Completion Gate

Done only when the summary file exists, required frontmatter is filled, source workspace/repo path is recorded when known, verification/follow-ups are explicit, no placeholders remain, and the final reply includes the saved path.

## Note Template

```markdown
---
title: <project title>
date: <YYYY-MM-DD>
type: project-summary
memory_type: project-summary
status: completed
repo: <repo/workspace name>
repo_path: <absolute repo/workspace path if known>
project_name: <project/workstream name>
branch: <branch name if known>
source_thread: <thread/session id or "current thread">
source_skill: project-completed-summary
source_sessions:
  - <thread/session id or "current thread">
confidence: high|medium|low
created_at: <ISO timestamp with timezone>
tags:
  - work/project-summary
  - work/project
---

# <Project Title>

## Summary
<3-6 bullets: what was done and why it matters.>

## Context
<Original goal, customer/system context, constraints, and important thread decisions.>

## Main Changes
- `<file or area>`: <what changed>

## Key Details / Logic
<Explain the important workflow, transformations, validations, API calls, parsing, posting, writing, error handling, scheduling behavior, or other logic that makes this work understandable later.>

## Problems Solved
- Problem: <issue>
  Solution: <fix>
  Remember: <future gotcha>

## Decisions
- <decision and reason>

## Verification
- <builds/tests/manual checks run, or "Not run" with reason>

## Follow-Ups
- [ ] <open item, risk, or reminder>

## Resume Context
Use this note when asked about `<project/repo/customer>`. Key search terms: <terms>.
```

## Safety

- Do not include secrets, tokens, passwords, private keys, full env values, or sensitive customer data.
- Do not copy long raw diffs. Summarize behavior and reference files.
- Do not search unrelated old AI agent sessions unless the user explicitly asks for a previous thread/session.
- If current context is insufficient, say what is missing and save a partial summary only if useful.
