---
name: project-autojournal
description: Automatically maintain Obsidian project memory from recent AI agent work. Use when asked to auto-journal, create project checkpoints, update project memory, process AI agent transcripts, summarize latest work into Obsidian, or run a scheduled project checkpoint workflow. Creates fresh checkpoint notes per project, updates a JSON state file, and handles ambiguous work by writing an unsorted draft/question instead of a daily productivity journal.
---

# Project Autojournal

Maintain project checkpoint memory in Obsidian from recent AI agent work. This skill is for scheduled or manual runs that inspect AI agent threads, workspace/repo history, and working tree changes when available, then write fresh project checkpoint notes.

## Defaults

- Vault: resolve via `references/project-memory-common.md`
- Project notes: `<vault>/<work-root>/Projects/<Project>/`
- Checkpoints: `<vault>/<work-root>/Checkpoints/<Project>/`
- State: `<vault>/<work-root>/.project-autojournal/state.json`
- Unclear work: `<vault>/<work-root>/Unsorted AI Work/`
- Timezone: `<timezone>`
- Repo roots: `<repo-roots>`
- Agent sources: configured in `references/project-memory-common.md`

Do not create a daily journal. Do not write productivity summaries.

## Shared Rules

Read `references/project-memory-common.md` before resolving vault paths, source registry rules, project identity, latest-wins behavior, or safety rules.

## Run Policy

- Write Obsidian automatically when project mapping is clear.
- Create a new checkpoint note for **every** project or workstream with meaningful unprocessed work in the same run. One note per run is only correct when exactly one candidate exists.
- Treat concurrent workstreams inside one repo as separate candidates. A repo with several active worktrees or branches produces one checkpoint per worktree, not one per repo.
- Preserve history: never overwrite older checkpoints.
- Update state after successful checkpoint writes.
- If meaningful unprocessed work is already fully captured by a newer manual/existing checkpoint, do not write a duplicate checkpoint; sync state to that checkpoint.
- Latest work wins over older Obsidian notes.
- Use git metadata and source file contents when needed to understand the work.
- Do not edit source/work files, commit, push, run deployments, or change production systems.
- Avoid raw dumps of transcripts, secrets, `.env` values, payroll/person data, customer exports, or long logs.
- Ignore project-autojournal's own runner logs, systemd service logs, JSONL output logs, final-message logs, any active/current autojournal run, and any past transcript whose main task was running `project-autojournal`.

## Candidate Enumeration And Completeness

A run must not stop after the first project it finds. Enumerate before writing, then resolve
every candidate.

1. **Enumerate first.** Build the complete candidate list before writing any note. Do not
   interleave discovery and writing: writing as you go is what makes a run stop at the first
   or most recent candidate and silently drop the rest.
2. **Key each candidate** by project plus workstream. The workstream key is the repo worktree
   path when available, otherwise the branch, otherwise the project name. Two active
   worktrees of the same repo are two candidates and get two checkpoints.
3. **Resolve every candidate.** Each one must end in exactly one of:
   - a checkpoint note written,
   - an already-captured state sync,
   - an unsorted draft/question,
   - an explicit skip with a recorded reason (noise, autojournal's own run, no meaningful
     change).
4. **Reconcile before finishing.** Compare candidates enumerated against candidates resolved.
   They must match. If any candidate is unresolved, the run is incomplete: say so in the final
   summary and name the unresolved candidates rather than reporting success.
5. **Do not rank candidates.** Recency ordering is for discovery only. Never let it become a
   reason to journal the newest workstream and drop the others.
6. **Partial failure is contained.** If one candidate fails to write, still resolve the rest,
   and update state only for the ones that succeeded.

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
      "workstreams": {
        "<repo-root>/example-feature-a": {
          "branch": "feature-a",
          "latestCheckpointPath": "<work-root>/Checkpoints/ExampleProject/2026-06-29 1530 - checkpoint - feature-a.md",
          "lastProcessedAt": "2026-06-29T15:30:00+03:00",
          "gitHead": "abcdef123"
        }
      },
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

If the shape needs to evolve, keep `version`, preserve existing data, and migrate
conservatively. `workstreams` is optional and additive: a project that has only ever had one
active worktree does not need it, and an older state file without it stays valid. Populate it
as soon as a project has two or more concurrent worktrees, because project-level
`lastProcessedAt` alone cannot express that one workstream is captured while another is not.

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
6. Identify related repo paths and inspect git metadata, including every active worktree.
7. Enumerate the full candidate list as described in `Candidate Enumeration And Completeness`.
8. Read latest Obsidian checkpoint/project note for each mapped candidate.
9. Compare with previous state; keep only new or changed information.
10. For each candidate in turn: if its inputs are fully captured by a newer checkpoint, write no duplicate note and sync state to that checkpoint; otherwise write a fresh checkpoint note; if mapping is unclear, write an unsorted question draft.
11. Continue until every enumerated candidate is resolved. Do not stop early because one note has been written.
12. If no meaningful new work remains for any candidate, create no notes and update only top-level no-op markers, except already-captured checkpoint sync.
13. Update `state.json` only after note/draft writes succeed, except no-op marker updates and already-captured checkpoint sync.
14. Reconcile enumerated against resolved candidates.
15. Return a terse summary: candidates found, checkpoints created, unsorted drafts created, already-captured sync count, skipped-with-reason count, no-op reason, errors. If candidates found does not equal candidates resolved, report the run as incomplete and name what was missed.

## Scheduled Run Behavior

For unattended runs:

- Prefer no user interaction.
- If confidence is high, write checkpoints.
- If confidence is low, create an unsorted draft/question.
- Resolve every enumerated candidate before finishing. An unattended run that writes one note
  and exits while other candidates are still unresolved is a failed run, not a successful one.
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
