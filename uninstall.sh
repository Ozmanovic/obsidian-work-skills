#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${PROJECT_MEMORY_CONFIG:-$HOME/.agents/project-memory.env}"
BIN_DIR="${WORK_SKILLS_BIN_DIR:-$HOME/.local/bin}"
AGENTS="${WORK_SKILLS_AGENTS:-all}"
CUSTOM_SKILLS_DIRS=()
REMOVE_CONFIG=0
REMOVE_TIMER=0

if [[ -n "${WORK_SKILLS_SKILLS_DIR:-}" ]]; then
  CUSTOM_SKILLS_DIRS+=("$WORK_SKILLS_SKILLS_DIR")
fi

usage() {
  cat <<'EOF'
Usage: ./uninstall.sh [options]

Options:
  --agents LIST      Comma-separated: all,codex,claude,copilot. Default: all
  --skills-dir PATH  Remove skills from a custom PATH. Can be repeated.
  --remove-config   Remove ~/.agents/project-memory.env
  --remove-timer    Disable and remove systemd user timer/service
  -h, --help        Show help.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --agents) AGENTS="$2"; shift 2 ;;
    --skills-dir) CUSTOM_SKILLS_DIRS+=("$2"); shift 2 ;;
    --remove-config) REMOVE_CONFIG=1; shift ;;
    --remove-timer) REMOVE_TIMER=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done

# shellcheck source=scripts/skill-targets.sh
. "$ROOT_DIR/scripts/skill-targets.sh"
work_skills_resolve_skill_dirs "$AGENTS" "${CUSTOM_SKILLS_DIRS[@]}"

if [[ "$REMOVE_TIMER" -eq 1 && -d "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user" ]]; then
  systemctl --user disable --now project-autojournal.timer >/dev/null 2>&1 || true
  rm -f "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/project-autojournal.timer"
  rm -f "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/project-autojournal.service"
  systemctl --user daemon-reload >/dev/null 2>&1 || true
fi

for skills_dir in "${WORK_SKILLS_RESOLVED_DIRS[@]}"; do
  for item in \
    project-memory-common.md \
    save-work-checkpoint \
    resume-project-context \
    project-completed-summary \
    retro-summary \
    implementation-finder \
    project-autojournal
  do
    rm -rf "$skills_dir/$item"
  done
done

rm -f "$BIN_DIR/project-autojournal-run"

if [[ "$REMOVE_CONFIG" -eq 1 ]]; then
  rm -f "$CONFIG_FILE"
fi

echo "Uninstalled work skills from:"
printf '  %s\n' "${WORK_SKILLS_RESOLVED_DIRS[@]}"
