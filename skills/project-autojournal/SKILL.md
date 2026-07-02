---
name: project-autojournal
description: Automatically maintain Obsidian project memory from recent AI agent work. Use when asked to auto-journal, create project checkpoints, update project memory, process AI agent transcripts, summarize latest work into Obsidian, or run a scheduled project checkpoint workflow. Creates fresh checkpoint notes per project, updates a JSON state file, and handles ambiguous work by writing an unsorted draft/question instead of a daily productivity journal.
---

# Project Autojournal

Maintain project checkpoint memory in Obsidian from recent AI agent work. This skill is for scheduled or manual runs that inspect AI agent threads, workspace/repo history, and working tree changes when available, then write fresh project checkpoint notes.

## Defaults

- Vault: resolve via `../project-memory-common.md`
- Project notes: `<vault>/<work-root>/Projects/<Project>/`
- Checkpoints: `<vault>/<work-root>/Checkpoints/<Project>/`
- State: `<vault>/<work-root>/.project-autojournal/state.json`
- Unclear work: `<vault>/<work-root>/Unsorted AI Work/`
- Timezone: `<timezone>`
- Repo roots: `<repo-roots>`
- Agent sources: configured in `../project-memory-common.md`

Do not create a daily journal. Do not write productivity summaries.

## Shared Rules

Read `../project-memory-common.md` before resolving vault paths, source registry rules, project identity, latest-wins behavior, or safety rules.

## Run Policy

- Write Obsidian automatically when project mapping is clear.
- Create a new checkpoint note for each project with meaningful unprocessed work.
- Preserve history: never overwrite older checkpoints.
- Update state after successful checkpoint writes.
- If meaningful unprocessed work is already fully captured by a newer manual/existing checkpoint, do not write a duplicate checkpoint; sync state to that checkpoint.
- Latest work wins over older Obsidian notes.
- Use git metadata and source file contents when needed to understand the work.
- Do not edit source/work files, commit, push, run deployments, or change production systems.
- Avoid raw dumps of transcripts, secrets, `.env` values, payroll/person data, customer exports, or long logs.
- Ignore project-autojournal's own runner logs, systemd service logs, JSONL output logs, final-message logs, any active/current autojournal run, and any past transcript whose main task was running `project-autojournal`.

## Sources

Process AI agent sources in recency order:

1. Codex JSONL sessions from configured Codex session roots.
2. Claude JSONL sessions from configured Claude project roots.
3. Copilot sources, best-effort:
   - workspace transcripts under configured Copilot workspace storage
   - resource files under configured Copilot workspace storage
   - global session DB under configured Copilot global storage
   - Copilot logs only for timing/errors, not work summaries
4. Workspace/repo metadata for repos mentioned in sessions:
   - branch
   - status
   - recent commits
   - changed filenames
   - diffs or file contents only when useful
5. Existing Obsidian project summaries and latest checkpoints.

Treat all AI agent transcript formats as internal and unstable. Parse defensively. Prefer user prompts, assistant final summaries, file edits, command outputs, and explicit checkpoint/project names over low-level tool noise. If `sqlite3` is unavailable, use Python `sqlite3` to inspect Copilot `session-store.db`.

## State Tracking

Use `<vault>/<work-root>/.project-autojournal/state.json` to avoid duplicates. Create it if missing.

If the state file is missing, treat the first run as a bootstrap run: process only sessions and git work from the current local day in `<timezone>`, unless the user explicitly asks for a historical backfill.

State updates are transactional:

- For checkpoint success: write checkpoint note first, then update project state.
- For already-captured work: write no note; update only the matching project state for inputs fully covered by the newer checkpoint.
- For unclear work: write unsorted draft first, then update `unassigned`.
- For no meaningful new work: write no checkpoint and no unsorted draft; update only top-level `lastRunAt`, `lastNoopAt`, and `lastNoopReason`.
- For failure: do not update state.
- Never change a project's `latestCheckpointPath`, `lastProcessedAt`, session markers, or `gitHeads` during a no-op run, unless the only change is recording ignored project-autojournal/noise sources or syncing work already captured by a newer checkpoint.

Recommended shape:

```json
{
  "version": 1,
  "lastRunAt": "2026-06-29T15:30:00+03:00",
  "lastNoopAt": "2026-06-30T15:30:00+03:00",
  "lastNoopReason": "No meaningful new project work found.",
  "projects": {
    "ExampleProject": {
      "status": "active",
      "repoPaths": ["<repo-root>/example"],
      "latestCheckpointPath": "<work-root>/Checkpoints/ExampleProject/2026-06-29 1530 - checkpoint - example.md",
      "lastProcessedAt": "2026-06-29T15:30:00+03:00",
      "codexSessions": {
        "<codex-session-root>/2026/06/29/session.jsonl": {
          "mtimeMs": 1782736200000,
          "size": 123456
        }
      },
      "claudeSessions": {
        "<claude-project-root>/example/session.jsonl": {
          "mtimeMs": 1782736200000,
          "size": 123456
        }
      },
      "copilotSessions": {
        "<copilot-workspace-storage>/hash/GitHub.copilot-chat/transcripts/session.jsonl": {
          "mtimeMs": 1782736200000,
          "size": 123456
        }
      },
      "gitHeads": {
        "<repo-root>/example": "abcdef123"
      }
    }
  },
  "unassigned": []
}
```

If the shape needs to evolve, keep `version`, preserve existing data, and migrate conservatively.

## Already-Captured Checkpoint Sync

Use this path when unprocessed AI sessions or git changes describe work already saved by a newer checkpoint, often from manual `save-work-checkpoint`.

Only treat work as already captured when the latest checkpoint:

- belongs to the same project/repo,
- is dated at or after the session/git work,
- describes the same files, decisions, current state, or next actions closely enough that a duplicate autojournal checkpoint would add no useful state.

When already captured:

- Create `0` checkpoint notes.
- Create `0` unsorted drafts.
- Update project `latestCheckpointPath` to the capturing checkpoint if it is newer than the state value.
- Update project `lastProcessedAt`, source session markers, and `gitHeads` only for the covered inputs.
- Update top-level `lastRunAt`; set `lastNoopAt` and `lastNoopReason` to show no new note was needed because work was already captured.
- Do not mark partial, conflicting, or uncertain inputs as processed. If unsure, write a checkpoint or unsorted draft instead.

## Project Mapping

Map work to a project using, in order:

1. Existing Obsidian project/checkpoint folder names.
2. Repo path in transcript metadata or working directory.
3. User-stated project/customer/system names in thread text.
4. Git remote/repo folder name.
5. Files changed and project/workstream/function names.

If a project note/folder does not exist but mapping is clear, create the checkpoint folder and the checkpoint. Do not require a completed project summary first.

If mapping is unclear, write a draft/question under `<vault>/<work-root>/Unsorted AI Work/` instead of guessing.

Question format:

```md
# Unassigned AI Work - 2026-06-29 1530

When running `project-autojournal`, I could not confidently assign this work:

<short explanation>

Is this a new project, an existing project, or a quick thing you do not want tracked?

Sources:
- <safe session/repo references>
```

## Checkpoint Format

Create one fresh checkpoint per project per run when there is meaningful new work.

Filename:

```txt
<vault>/<work-root>/Checkpoints/<Project>/YYYY-MM-DD HHmm - checkpoint - <short-topic>.md
```

Use Obsidian Markdown and concise frontmatter:

```md
---
title: <Project> checkpoint
date: YYYY-MM-DD
type: checkpoint
memory_type: checkpoint
project: <Project>
project_name: <Project>
status: active
source: project-autojournal
source_skill: project-autojournal
source_sessions:
  - <safe session path or id>
confidence: high|medium|low
created_at: <ISO timestamp with timezone>
---

# <Project> Checkpoint - YYYY-MM-DD HH:mm

## Task context

<Why this work exists and current overall state.>

## What changed

- <meaningful completed work since last checkpoint>

## Current state

- <workspace/repo/worktree state, changed files, verification/runtime status if known>

## Next

- <concrete next actions>

## Watch

- <risks, blockers, unclear items; omit if none>

## Sources

- <session paths, repo paths, commits, or safe references>
```

Keep notes useful for resuming work. Avoid tracking time spent, output volume, or productivity judgments.

## Workflow

1. Load state file if it exists.
2. If state is missing, limit discovery to the current local day in `<timezone>`.
3. Find recently changed AI agent session files not fully processed by state.
4. Exclude the active autojournal run, prior project-autojournal runs, and logs under `~/.local/state/project-autojournal`.
5. Extract safe summaries of meaningful work.
6. Identify related repo paths and inspect git metadata.
7. Read latest Obsidian checkpoint/project note for each mapped project.
8. Compare with previous state; keep only new or changed information.
9. If new inputs are fully captured by a newer checkpoint, write no duplicate note and sync state to that checkpoint.
10. Write fresh checkpoint notes for mapped projects with meaningful uncaptured work.
11. Write unsorted question drafts for unclear work.
12. If no meaningful new work remains after comparison, create no notes and update only top-level no-op markers, except already-captured checkpoint sync.
13. Update `state.json` only after note/draft writes succeed, except no-op marker updates and already-captured checkpoint sync.
14. Return a terse summary: checkpoints created, unsorted drafts created, already-captured sync count, no-op reason, errors.

## Scheduled Run Behavior

For unattended runs:

- Prefer no user interaction.
- If confidence is high, write checkpoints.
- If confidence is low, create an unsorted draft/question.
- If there is no meaningful new project work, create nothing except no-op state markers and return `No new project work found.`
- If Obsidian or transcript paths are unavailable, fail clearly and do not update state.
- If another run is active, exit without doing work.
- Treat the scheduled runner's own transcript/output as implementation noise, not project work.

## No-Op Rules

A run is a no-op when all new or changed inputs are only project-autojournal logs/transcripts, already-processed AI agent sessions, unchanged git heads, or work already captured by the latest checkpoint.

Already-captured checkpoint sync is a special no-new-note path: it may update per-project source markers and `latestCheckpointPath` when a newer manual/existing checkpoint already covers the work.

On no-op:

- Create `0` checkpoint notes.
- Create `0` unsorted drafts.
- Do not modify project `latestCheckpointPath`.
- Do not modify project `lastProcessedAt`.
- Do not update project session markers or `gitHeads`, except to record ignored autojournal/noise sources or already-captured checkpoint sync.
- Update only top-level `lastRunAt`, `lastNoopAt`, and `lastNoopReason`.
- Final answer must include `No new project work found.`

## Safety Checks

Before writing:

- Confirm path is inside `<vault>/<work-root>/`.
- Confirm note does not duplicate the latest checkpoint.
- Confirm content does not include secrets, raw env values, or long personal/customer data dumps.
- Confirm the checkpoint is project state, not worker productivity tracking.
