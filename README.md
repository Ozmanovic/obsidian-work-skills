# Work Skills

Obsidian work-memory skills for saving and resuming project or workstream context.

The package is built around project checkpoints, not productivity tracking.

## Included Skills

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

## Install

```bash
cd work-skills
./install.sh --vault /path/to/ObsidianVault --repo-roots "$HOME/git" --timezone Europe/Helsinki
./doctor.sh
```

Default install locations:

- skills: `~/.agents/skills`
- config: `~/.agents/project-memory.env`
- autojournal runner: `~/.local/bin/project-autojournal-run`

### Install Targets

The default `~/.agents/skills` target is the shared OpenAI/Codex-style location used by this package and is also discoverable by VS Code Agent Skills.

Alternative personal targets:

```bash
# Claude Code personal skills
WORK_SKILLS_SKILLS_DIR="$HOME/.claude/skills" ./install.sh --vault /path/to/ObsidianVault

# GitHub Copilot / VS Code personal skills
WORK_SKILLS_SKILLS_DIR="$HOME/.copilot/skills" ./install.sh --vault /path/to/ObsidianVault
```

Project-local targets:

```bash
# Copilot / VS Code workspace skills
WORK_SKILLS_SKILLS_DIR="/path/to/repo/.github/skills" ./install.sh --vault /path/to/ObsidianVault

# Claude workspace skills
WORK_SKILLS_SKILLS_DIR="/path/to/repo/.claude/skills" ./install.sh --vault /path/to/ObsidianVault
```

For team rollout, prefer project-local skills only when the whole repo/team should use the same work-memory behavior. Otherwise use personal skills.

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
Use $implementation-finder to scout similar implementations for this job/spec: ...
Use $save-work-checkpoint to save the current project state to Obsidian.
Use $resume-project-context to resume this project.
Use $project-completed-summary to save this completed project to Obsidian.
Use $retro-summary to summarize completed project/work into Obsidian. Project/work: ...
```

## Skill Guide

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

Use before starting a change when you want similar prior work and a recommended approach.

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

- Codex/OpenAI agents: supported by the included `SKILL.md` folders and `agents/openai.yaml` metadata.
- Claude Code: supported by `SKILL.md` folders. Install to `~/.claude/skills` for personal skills or `.claude/skills` for repo-local skills.
- GitHub Copilot / VS Code: supported through Agent Skills. Install to `~/.copilot/skills`, `.github/skills`, or the shared `~/.agents/skills` location when your VS Code setup discovers it.
- Prompt files: optional convenience wrappers for slash-command style prompts; not required for the core skills.
- Scheduled `project-autojournal`: currently Codex CLI powered because `scripts/project-autojournal-run` invokes `codex exec`.

## Optional Autojournal Timer

Autojournal timer is opt-in. It creates a user-level systemd timer that runs the current Codex-powered `project-autojournal` runner once per day.

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

Run this after install or when something feels broken:

```bash
./doctor.sh
```

It checks:

- config exists
- vault exists and is writable
- skills are installed
- `rg` exists
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

## Notes For Teams

Recommended rollout:

1. Install manual skills first.
2. Run `doctor.sh`.
3. Use manual checkpoint/resume for a few days.
4. Enable autojournal only for people who explicitly want it.

The timer should not be installed by default on coworker machines.
