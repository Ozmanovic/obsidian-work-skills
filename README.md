# Work Skills

Codex skills for saving and resuming software project memory in Obsidian.

The package is built around project checkpoints, not productivity tracking.

## Included Skills

- `save-work-checkpoint` - save current in-progress project state.
- `resume-project-context` - resume from latest checkpoint/project summary/repo facts.
- `project-completed-summary` - save a durable finished-project summary.
- `retro-summary` - recover older completed work from previous agent sessions.
- `implementation-finder` - scout similar implementations before coding.
- `project-autojournal` - optional scheduled checkpoint autosave from recent AI agent work.

## What It Reads

Depending on skill and config:

- Obsidian notes under `<vault>/<work-root>/`
- current repo metadata, diffs, commits, and relevant source files
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

- edit source code
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

Use these in Codex:

```text
Use $implementation-finder to scout similar implementations for this job/spec: ...
Use $save-work-checkpoint to save the current project state to Obsidian.
Use $resume-project-context to resume this project.
Use $project-completed-summary to save this completed project to Obsidian.
Use $retro-summary to summarize completed project/work into Obsidian. Project/work: ...
```

## Optional Autojournal Timer

Autjournal timer is opt-in. It creates a user-level systemd timer that runs `project-autojournal` once per day.

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
- Codex CLI exists for autojournal
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
