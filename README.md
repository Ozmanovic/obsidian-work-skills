# Work Skills

Obsidian work-memory skills for saving and resuming project or workstream context.

The package is built around project checkpoints, not productivity tracking.

## Benefits

- Move between Codex, Claude Code, and GitHub Copilot without losing project context.
- Start an empty agent session with immediate context from previous project notes and checkpoints.
- Return to old projects faster when making tweaks, answering client/colleague questions, or checking why something was done.
- Resume after a few days away without rereading full chat threads or rebuilding the whole mental model.
- Multitask across projects with less context kept in your head; Obsidian becomes the second brain for work state.
- Keep project memory in your own vault as Markdown files, not locked inside one agent chat history.

## Included Skills

- `setup-obsidian-work-skills` - first-run setup for vault/config/source checks.
- `save-work-checkpoint` - save current in-progress project state.
- `resume-project-context` - resume from latest checkpoint/project summary/repo facts.
- `project-completed-summary` - save a durable finished-project summary.
- `retro-summary` - recover older completed work from previous agent sessions.
- `implementation-finder` - scout similar implementations before building/changing work.
- `project-autojournal` - optional scheduled checkpoint autosave from recent AI agent work.

## What It Reads

Depending on skill and config:

- Obsidian notes under `<vault>/<work-root>/`
- current workspace/repo metadata, diffs, commits, and relevant files when available
- local Codex session files
- local Claude session files
- local GitHub Copilot / VS Code chat files, best-effort

Missing agent sources are warnings, not failures.

## What It Writes

- Obsidian project checkpoint notes
- Obsidian completed project summaries
- implementation scout notes
- optional autojournal state/log files
- optional unsorted draft questions when project mapping is unclear

It should not:

- edit source/work files
- commit, push, or deploy
- create daily journals
- create productivity reports
- include secrets, env values, raw customer exports, or full transcripts

## Prerequisites

Required:

- A local Obsidian vault folder path that the agent can read and write.
- At least one supported agent surface: Codex/OpenAI, Claude Code, or GitHub Copilot / VS Code with Agent Skills.
- For the recommended install path: Node/npm with `npx`.

Recommended:

- Obsidian desktop app installed so you can view/search the generated notes.
- `rg` / ripgrep available on `PATH` for fast searches across repos, notes, and local agent sessions. If missing, skills fall back to slower `grep`/`find`/`git grep` style search.
- `git` available on `PATH` if you want repo/workspace facts, commit history, diffs, and implementation search.
- Local AI session history enabled for the agents you want to journal from: Codex, Claude, and/or Copilot.

Not required:

- Obsidian CLI.
- Obsidian community plugins.
- A separate Obsidian agent skill.
- Obsidian running while notes are written.

Optional Obsidian-related helpers:

- An Obsidian Markdown skill can improve note formatting with wikilinks, callouts, embeds, and richer properties, but this package already includes its own note templates.
- Obsidian CLI can be useful for interactive vault operations when Obsidian is open, but scheduled autojournal and normal checkpoint writes use direct Markdown file writes.

Optional autojournal only:

- A cloned copy of this repo or the script installer, because the packaged timer uses `scripts/project-autojournal-run`.
- Codex CLI, because the scheduled runner currently invokes `codex exec`.
- user-level `systemd` timers if you want scheduled runs on Linux/WSL.

## Install

Recommended skills.sh-style path:

```bash
npx skills@latest add Ozmanovic/obsidian-work-skills
```

Pick the skills you want and the agents you want to install them for. For first setup, install all skills and include `setup-obsidian-work-skills`.

Then run this in your agent:

```text
Use $setup-obsidian-work-skills to configure my Obsidian work skills.
```

If you already know your vault path:

```text
Use $setup-obsidian-work-skills to configure my Obsidian work skills. Vault: /path/to/ObsidianVault
```

The setup skill creates or updates:

```text
~/.agents/project-memory.env
```

That config is shared by Codex, Claude Code, Copilot, and the optional autojournal runner.

### Script Install

The scripts are an optional fallback for cloned repos, repeatable local installs, offline/manual setup, scheduled autojournal runner installation, and troubleshooting. They are not required for normal skills.sh-style manual checkpoint/resume usage.

```bash
cd work-skills
./install.sh --vault /path/to/ObsidianVault --repo-roots "$HOME/git" --timezone Europe/Helsinki
./doctor.sh
```

By default, personal skills are installed for all supported local agent surfaces:

- Codex/OpenAI agents: `~/.agents/skills`
- Claude Code: `~/.claude/skills`
- GitHub Copilot / VS Code: `~/.copilot/skills`
- config: `~/.agents/project-memory.env`
- autojournal runner: `~/.local/bin/project-autojournal-run`

### Script Install Targets

Install only for one agent:

```bash
./install.sh --agents codex --vault /path/to/ObsidianVault
./install.sh --agents claude --vault /path/to/ObsidianVault
./install.sh --agents copilot --vault /path/to/ObsidianVault
```

Install for multiple agent targets:

```bash
./install.sh --agents codex,claude --vault /path/to/ObsidianVault
./install.sh --agents all --vault /path/to/ObsidianVault
```

The agent targets map to:

- `codex`: `~/.agents/skills`
- `claude`: `~/.claude/skills`
- `copilot`: `~/.copilot/skills`

Install to a custom personal or project-local path:

```bash
# Copilot / VS Code workspace skills
./install.sh --skills-dir /path/to/repo/.github/skills --vault /path/to/ObsidianVault

# Claude workspace skills
./install.sh --skills-dir /path/to/repo/.claude/skills --vault /path/to/ObsidianVault

# Codex repo-local skills
./install.sh --skills-dir /path/to/repo/.agents/skills --vault /path/to/ObsidianVault
```

Edit config later:

```bash
nano ~/.agents/project-memory.env
```

Example config:

```sh
PROJECT_MEMORY_VAULT=/path/to/ObsidianVault
PROJECT_MEMORY_WORK_ROOT=Work
PROJECT_MEMORY_REPO_ROOTS=$HOME/git:$HOME/work
PROJECT_MEMORY_TIMEZONE=Europe/Helsinki
PROJECT_MEMORY_AGENT_SOURCES=codex,claude,copilot
PROJECT_MEMORY_AUTOJOURNAL_TIME=15:30
```

## Manual Usage

Use these in any agent surface that has these skills/instructions installed:

```text
Use $setup-obsidian-work-skills to configure my Obsidian work skills.
Use $implementation-finder to scout similar implementations for this job/spec: ...
Use $save-work-checkpoint to save the current project state to Obsidian.
Use $resume-project-context to resume this project.
Use $project-completed-summary to save this completed project to Obsidian.
Use $retro-summary to summarize completed project/work into Obsidian. Project/work: ...
```

## Skill Guide

### `setup-obsidian-work-skills`

Use once after install, or again when changing vault path, repo roots, agent sources, or autojournal settings.

Example prompt:

```text
Use $setup-obsidian-work-skills to configure my Obsidian work skills. Vault: /path/to/ObsidianVault
```

Writes or updates:

```text
~/.agents/project-memory.env
```

It checks vault write access, agent source locations, `git`, optional `rg`, and optional Codex CLI for scheduled autojournal.

### `save-work-checkpoint`

Use when work is in progress and you want a durable handoff note before stopping, switching tasks, or asking another agent to continue.

Example prompt:

```text
Use $save-work-checkpoint to save where this project is now.
```

Writes:

```text
<vault>/<work-root>/Checkpoints/<project>/YYYY-MM-DD HHmm - checkpoint - <topic>.md
```

Example chat output:

```text
- Saved checkpoint: Work/Checkpoints/Example/2026-07-02 1530 - checkpoint - import cleanup.md
- Captured current state, open questions, next actions, files touched.
```

### `resume-project-context`

Use when returning to a project/workstream and you need the latest reliable state before continuing.

Example prompt:

```text
Use $resume-project-context to resume Example project.
```

Example output shape:

```text
Project: Example
Task context: ...
What has been done so far: ...
Where left off: ...
Open questions: ...
What is next: ...
```

Rules:

- Reads newest checkpoint first.
- Reads completed summary if useful.
- Newer checkpoint/workspace facts override older completed summaries.
- Does not write a new note unless asked.

### `project-completed-summary`

Use when a piece of work is finished and should be searchable months later.

Example prompt:

```text
Use $project-completed-summary to save this completed project to Obsidian.
```

Writes:

```text
<vault>/<work-root>/Projects/<project>/YYYY-MM-DD - <project>.md
```

Captures:

- what changed and why
- important details/logic
- problems solved
- decisions
- verification
- follow-ups

### `retro-summary`

Use when old work was completed before summaries/checkpoints existed and you want to reconstruct it from prior AI sessions plus local workspace/repo evidence.

Example prompt:

```text
Use $retro-summary to summarize completed project/work into Obsidian. Project/work: Example invoice cleanup from June.
```

If no scope is provided, it asks for at least one clue instead of searching everything.

### `implementation-finder`

Use before starting a project when you want similar prior work and a recommended approach.

Example prompt:

```text
Use $implementation-finder to scout similar implementations for this job/spec: Build a checkpoint export for project notes. It should write Markdown to Obsidian, use existing config if present, avoid daily productivity logs, and work from recent AI session evidence.
```

If invoked without a real job/spec, it asks:

```text
What job/spec should I scout similar implementations for? Describe what needs to be built or changed, where it should live if known, what systems/data are involved, and any constraints. More detail is better.
```

Writes an implementation scout note under the project checkpoint folder when enough context exists.

### `project-autojournal`

Use manually or by optional timer to scan recent AI agent work and create checkpoint notes only when meaningful new work exists.

It does not create daily journals or productivity reports.

Behavior:

- Clear project mapping: writes one fresh checkpoint per project.
- Unclear project mapping: writes an unsorted draft/question.
- No new work: writes no checkpoint and updates only no-op state markers.
- Work already captured by a newer manual checkpoint: writes no duplicate and syncs state.

## Agent Compatibility

The reusable part is the skill instructions: they are meant to be agent-agnostic and can track any work that has enough evidence, not only software work.

Current package support:

- Codex/OpenAI agents: supported by `SKILL.md` folders under `~/.agents/skills` or repo-local `.agents/skills`.
- Claude Code: supported by `SKILL.md` folders under `~/.claude/skills` or repo-local `.claude/skills`.
- GitHub Copilot / VS Code: supported through Agent Skills under `~/.copilot/skills` or repo-local `.github/skills`.
- Prompt files: optional convenience wrappers for slash-command style prompts; not required for the core skills.
- Scheduled `project-autojournal`: currently Codex CLI powered because `scripts/project-autojournal-run` invokes `codex exec`.

## Optional Autojournal Timer

Autojournal timer is opt-in. It creates a user-level systemd timer that runs the current Codex-powered `project-autojournal` runner once per day.

The packaged timer requires a cloned repo/script install so `project-autojournal-run` exists under `~/.local/bin`. Normal `npx skills` installation is enough for manual skill usage, but not for the packaged scheduled runner.

Install but do not enable:

```bash
./scripts/install-autojournal-timer.sh --timer-time 15:30
```

Install and enable:

```bash
./scripts/install-autojournal-timer.sh --timer-time 15:30 --enable
```

Disable:

```bash
systemctl --user disable --now project-autojournal.timer
```

Check:

```bash
systemctl --user list-timers project-autojournal.timer --no-pager
```

Logs:

```text
~/.local/state/project-autojournal/
```

## Doctor

Optional troubleshooting tool for cloned/script installs, or when something feels broken:

```bash
./doctor.sh
```

It checks:

- config exists
- vault exists and is writable
- `.obsidian` vault marker exists, with a warning if missing
- skills are installed
- `rg` exists, with a warning if missing
- `git` exists, with a warning if missing
- Obsidian command exists when available, informational only
- Codex CLI exists for the optional scheduled autojournal runner
- repo roots exist
- agent session sources are present or absent
- systemd timer status
- packaged skills validate

## Validate Package

```bash
./scripts/validate-skills.sh
bash -n install.sh uninstall.sh doctor.sh scripts/*.sh
```

## Uninstall

```bash
./uninstall.sh
```

Remove config and timer too:

```bash
./uninstall.sh --remove-config --remove-timer
```

## Recommended Rollout

1. Install skills with `npx skills@latest add Ozmanovic/obsidian-work-skills`.
2. Run `setup-obsidian-work-skills` in your agent.
3. Use manual checkpoint/resume for a few days.
4. Run `doctor.sh` only if you cloned the repo or need troubleshooting.
5. Enable autojournal only when you explicitly want scheduled checkpointing.

The timer is opt-in and should not be enabled by default.
