---
name: setup-obsidian-work-skills
description: Configure Obsidian Work Skills after installation. Use when the user installs this package, needs first-run setup, wants to connect an Obsidian vault, configure repo roots or agent session sources, verify the package, or decide whether to enable optional autojournal scheduling.
---

# Setup Obsidian Work Skills

## Overview

Configure the local project-memory environment used by the Obsidian work skills. Keep setup boring: write one config file, verify paths, explain optional pieces, and avoid enabling scheduled automation unless the user explicitly asks.

Read `references/project-memory-common.md` before writing config or explaining source locations.

## Workflow

1. Resolve the Obsidian vault:
   - Use an explicit user-provided path first.
   - Otherwise check `PROJECT_MEMORY_VAULT`, `OBSIDIAN_VAULT`, then `~/.agents/project-memory.env`.
   - If still unknown, ask one short question for the vault path.
   - Verify the folder exists and is writable.
   - Warn, but do not fail, when `.obsidian/` is missing.

2. Choose defaults:
   - Config path: `PROJECT_MEMORY_CONFIG` if set, otherwise `~/.agents/project-memory.env`.
   - Work root: `Work`.
   - Repo roots: `$HOME/git` when it exists, otherwise current repo root if available.
   - Timezone: system timezone, otherwise UTC.
   - Agent sources: available local sources among Codex, Claude, and Copilot.

3. Write or update config:
   - Preserve an existing config unless the user asks to overwrite.
   - Add missing keys without removing user edits.
   - Never store secrets.
   - Use shell-style key/value lines:

```sh
PROJECT_MEMORY_VAULT=/path/to/ObsidianVault
PROJECT_MEMORY_WORK_ROOT=Work
PROJECT_MEMORY_REPO_ROOTS=$HOME/git:$HOME/work
PROJECT_MEMORY_TIMEZONE=Europe/Helsinki
PROJECT_MEMORY_AGENT_SOURCES=codex,claude,copilot
PROJECT_MEMORY_CODEX_SESSIONS=
PROJECT_MEMORY_CLAUDE_PROJECTS=
PROJECT_MEMORY_COPILOT_WORKSPACE_STORAGE=
PROJECT_MEMORY_COPILOT_GLOBAL_STORAGE=
PROJECT_MEMORY_AUTOJOURNAL_TIME=15:30
```

4. Verify tools:
   - `rg`/ripgrep is recommended for fast search. If missing, explain that skills can fall back to slower `grep`/`find` search.
   - `git` is recommended for repo facts, diffs, commits, and implementation search.
   - Obsidian CLI is not required; notes are written as Markdown files.
   - Codex CLI is required only for the packaged scheduled autojournal runner.

5. Verify installed skills:
   - Check for expected skill folders in the active agent skill directory when discoverable.
   - If the package repo is available and contains `doctor.sh`, offer to run it or run it when the user asked for verification.
   - If `doctor.sh` is unavailable, do manual checks from this workflow.

6. Explain autojournal safely:
   - It is optional and off by default.
   - The packaged timer uses a user-level systemd timer and a Codex-powered runner.
   - Scheduled autojournal needs the cloned repo/script installer so `project-autojournal-run` is installed. Normal `npx skills` install is enough for manual skill usage, not for the packaged timer.
   - Do not install, enable, or change a timer unless the user explicitly asks.
   - If enabled, it writes checkpoints only when meaningful new work exists; it should not create daily productivity journals.

## Completion

End with:

- Config path written or confirmed.
- Vault path and work root.
- Which agent sources were found or missing.
- Whether `rg`, `git`, and optional Codex CLI are available.
- Whether autojournal timer is disabled, enabled, or not configured.
