---
name: save-work-checkpoint
description: Save an in-progress work/project checkpoint to the user's Obsidian vault from current thread, workspace/repo state, or AI agent session evidence. Use when the user says "Save checkpoint", "save work checkpoint", "checkpoint to Obsidian", or asks to preserve where current work was left off.
---

# Save Work Checkpoint

Create an Obsidian checkpoint note for active work. The note is the durable handoff memory, so it should be detailed enough for another agent to continue without rereading the thread. The reply to the user stays concise.

User communication rule: "When reporting/answering to me. Be concise. Sacrifice grammar for the sake of concision."

## Default Output

- Vault: resolve via `../project-memory-common.md`
- Folder: `<vault>/<work-root>/Checkpoints/<project-name>/`
- Filename: `<YYYY-MM-DD HHmm> - checkpoint - <short-title>.md`
- Create folders if missing.
- Use Obsidian Markdown with frontmatter.

## Shared Rules

Read `../project-memory-common.md` when current visible thread is incomplete, project identity is unclear, or AI agent session evidence may contain the latest work.

## Workflow

1. Identify current project:
   - Use the shared project identity order.
   - Use `git rev-parse --show-toplevel` for repo metadata when available.
   - Use branch name, user request, current thread, AI session evidence, and changed files for title.
   - Ask one short question only if project identity is unclear.
2. Gather checkpoint facts:
   - Current visible thread: goal, what happened, decisions, blockers, next intended action.
   - If the current thread is not enough, inspect relevant AI agent sources from the shared rules.
   - Capture open questions separately from blockers: unresolved business rules, missing credentials/config, unclear ownership, unverified assumptions, and decisions waiting for the user/customer.
   - Workspace/repo state if useful: `git status --short`, `git branch --show-current`, `git diff --stat`, `git diff --name-only`, recent commits.
   - Read only directly relevant files if needed to explain where implementation stopped.
3. Write robust note:
   - Write for resume quality, not brevity. The checkpoint may be detailed.
   - Capture task context, work done, decisions made and why, problems faced/solved, exact repo state, open questions, and concrete remaining work.
   - Include a dedicated open questions section when any unresolved questions exist; include all meaningful open questions, grouped if many.
   - Separate "what still needs doing" from "open questions". Include code/test/config/ask-person actions.
   - Include open risks, partial assumptions, commands/tests run, and files touched.
   - Use enough context that another agent can resume without rereading the whole thread or guessing from code alone.
   - Do not include a "Resume Prompt" or instructions telling a future agent to start work. The checkpoint is context, not an execution request.
4. Reply to user:
   - 1-3 terse bullets max.
   - Include saved path.
   - Do not paste the whole note unless asked.

## Completion Gate

Done only when the checkpoint file exists, required frontmatter is filled, no placeholders remain, open questions are separated from next actions, verification is explicit, and the final reply includes the saved path.

## Note Template

```markdown
---
title: <checkpoint title>
date: <YYYY-MM-DD>
time: <HH:mm>
type: work-checkpoint
memory_type: checkpoint
status: in-progress
repo: <repo/workspace name>
repo_path: <absolute repo/workspace path if known>
project_name: <project/workstream name>
branch: <branch name if known>
source_skill: save-work-checkpoint
source_sessions:
  - <thread/session id or "current thread">
confidence: high|medium|low
created_at: <ISO timestamp with timezone>
tags:
  - work/checkpoint
  - work/project
---

# <Checkpoint Title>

## Task Context
<Why this project exists, what problem it solves, and the key constraints. Use a clear causal paragraph, but do not overcompress.>

## What Has Been Done So Far
- <implementation/research/config work completed>

## Decisions Made And Why
- <decision>: <reason/tradeoff>

## Problems Faced / Solved
- <problem>: <how it was handled>

## Current State
<Branch/workspace state, tracked/untracked files if relevant, verification/runtime status, exact stopping point, and known incomplete behavior.>

## Open Questions
- <unresolved business/config/technical question; omit this section only if none exist>

## What Still Needs Doing
1. <next work/test/config/customer-question action>
2. <next work/test/config/customer-question action>

## Important Details
- <API/mapping/business/file-format/customer-specific detail worth remembering>

## Files / Areas
- `<file or area>`: <why relevant>

## Problems / Blockers
- <issue, if any>

## Verification
- <commands/tests/manual checks run, or "Not run" with reason>
```

## Safety

- Do not include secrets, tokens, passwords, private keys, full env values, or sensitive customer data.
- Do not dump raw diffs or long transcript excerpts.
- Save partial checkpoint if the state is useful but imperfect.
