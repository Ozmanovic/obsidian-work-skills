# Project Memory Common

Shared rules for project/work memory skills. Use this when a checkpoint, resume, completed summary, implementation scout, or retro summary needs evidence beyond the visible thread.

## Runtime Config

Read config from `PROJECT_MEMORY_CONFIG` if set, otherwise `~/.agents/project-memory.env`.
Environment variables override config file values.

Supported config:

```sh
PROJECT_MEMORY_VAULT=/path/to/ObsidianVault
PROJECT_MEMORY_WORK_ROOT=Work
PROJECT_MEMORY_REPO_ROOTS=$HOME/git:$HOME/work
PROJECT_MEMORY_TIMEZONE=Europe/Helsinki
PROJECT_MEMORY_AGENT_SOURCES=codex,claude,copilot
PROJECT_MEMORY_CODEX_SESSIONS=$HOME/.codex/sessions
PROJECT_MEMORY_CLAUDE_PROJECTS=$HOME/.claude/projects
PROJECT_MEMORY_COPILOT_WORKSPACE_STORAGE=$HOME/.vscode-server/data/User/workspaceStorage
PROJECT_MEMORY_COPILOT_GLOBAL_STORAGE=$HOME/.vscode-server/data/User/globalStorage/github.copilot-chat
PROJECT_MEMORY_AUTOJOURNAL_TIME=15:30
```

Use defaults only when config is missing:

- `<work-root>` defaults to `Work`.
- `<repo-roots>` defaults to `$HOME/git` when it exists, otherwise the current repo root.
- `<timezone>` defaults to system timezone, then UTC.
- `<agent-sources>` defaults to available local sources among Codex, Claude, and Copilot.

## Vault Resolution

Resolve the Obsidian vault once per task and refer to it as `<vault>`.
Resolve the work folder as `<work-root>`; default is `Work`.

Resolution order:

1. Use an explicit vault path from the user request.
2. Use `PROJECT_MEMORY_VAULT`, then `OBSIDIAN_VAULT`.
3. Read `PROJECT_MEMORY_CONFIG` if set, otherwise `~/.agents/project-memory.env`.
4. If writing and no vault can be resolved, ask one short question for the vault path.

Config file format is shell-style:

```sh
PROJECT_MEMORY_VAULT=/path/to/ObsidianVault
PROJECT_MEMORY_WORK_ROOT=Work
```

All write paths must stay inside `<vault>/<work-root>/`.
Do not hardcode the vault path in individual skills.

## Repo Roots

Resolve workspace/repo search roots from `PROJECT_MEMORY_REPO_ROOTS`.
Treat it as a colon-separated list. Search only existing directories.
If missing, use `$HOME/git` when it exists. If not, use current repo root from `git rev-parse --show-toplevel`.

Do not hardcode personal repo paths.

## Timezone

Use `PROJECT_MEMORY_TIMEZONE` for filenames, state timestamps, and scheduled runs.
If missing, use the system timezone. If unknown, use UTC.

## Source Registry

Prefer sources in this order:

1. Obsidian notes:
   - `<vault>/<work-root>/Checkpoints/<project-name>/`
   - `<vault>/<work-root>/Projects/<project-name>/`
   - `<vault>/<work-root>/.project-autojournal/state.json`
2. Current workspace/repo facts when available:
   - branch, status, recent commits, changed filenames
   - diffs or files only when needed to explain state
3. AI agent session sources:
   - Codex sessions:
     - `PROJECT_MEMORY_CODEX_SESSIONS`
     - `$CODEX_HOME/sessions`
     - `$HOME/.codex/sessions`
   - Claude sessions:
     - `PROJECT_MEMORY_CLAUDE_PROJECTS`
     - `$CLAUDE_CONFIG_DIR/projects`
     - `$HOME/.claude/projects`
   - GitHub Copilot / VS Code sources, best-effort:
     - `PROJECT_MEMORY_COPILOT_WORKSPACE_STORAGE/*/GitHub.copilot-chat/transcripts/*.jsonl`
     - `PROJECT_MEMORY_COPILOT_WORKSPACE_STORAGE/*/GitHub.copilot-chat/chat-session-resources/**/content.txt`
     - `PROJECT_MEMORY_COPILOT_GLOBAL_STORAGE/session-store.db`
     - VS Code Copilot logs only for timing/errors, not work summaries

Copilot storage is version-dependent. Parse defensively. If `sqlite3` is unavailable, use Python `sqlite3` to inspect `session-store.db`. Treat transcripts and DB rows as internal formats.

If an agent source is not configured or not present, warn only when useful. Missing Claude/Copilot/Codex stores are absent evidence, not failure.

## Project Identity

Map work to a project using this order:

1. Existing Obsidian project/checkpoint folder.
2. Repo path or workspace path in transcript/tool metadata.
3. User-stated customer, project, workstream, task, system, integration, or function name.
4. Git remote/repo folder and branch.
5. Changed files and function folders.

Ask one short question only when two or more plausible projects remain and the choice changes the note path.

## Latest Wins

Newest reliable project/work state wins over older notes. Prefer explicit checkpoint/current workspace or repo facts over older completed summaries when they conflict. Mention conflict only when it affects next action.

## Standard Frontmatter

Use these shared fields when writing notes, in addition to any skill-specific fields:

```yaml
memory_type: checkpoint | project-summary | implementation-scout | retro-summary
project_name: <project name>
repo: <repo/workspace name if known>
repo_path: <absolute repo/workspace path if known>
branch: <branch if known>
source_skill: <skill name>
source_sessions:
  - <safe session path or id>
confidence: high | medium | low
created_at: <ISO timestamp with timezone>
```

## Safety

Never include secrets, tokens, passwords, private keys, full env values, full customer exports, raw transcript dumps, or long diffs. Summarize behavior and cite source paths.

## Completion Gate

Before reporting done:

- Target note exists at the intended Obsidian path, unless the task is resume-only.
- Frontmatter has the required project/repo/status fields for that skill.
- No `<placeholder>` text remains.
- Open questions are separated from next actions.
- Verification is explicit: commands/checks run, or `Not run` with reason.
- Reply includes the saved path for write tasks.
