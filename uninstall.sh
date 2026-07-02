#!/usr/bin/env bash
set -euo pipefail

SKILLS_DIR="${WORK_SKILLS_SKILLS_DIR:-$HOME/.agents/skills}"
CONFIG_FILE="${PROJECT_MEMORY_CONFIG:-$HOME/.agents/project-memory.env}"
BIN_DIR="${WORK_SKILLS_BIN_DIR:-$HOME/.local/bin}"
REMOVE_CONFIG=0
REMOVE_TIMER=0

usage() {
  cat <<'EOF'
Usage: ./uninstall.sh [options]

Options:
  --remove-config   Remove ~/.agents/project-memory.env
  --remove-timer    Disable and remove systemd user timer/service
  -h, --help        Show help.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --remove-config) REMOVE_CONFIG=1; shift ;;
    --remove-timer) REMOVE_TIMER=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done

if [[ "$REMOVE_TIMER" -eq 1 && -d "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user" ]]; then
  systemctl --user disable --now project-autojournal.timer >/dev/null 2>&1 || true
  rm -f "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/project-autojournal.timer"
  rm -f "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/project-autojournal.service"
  systemctl --user daemon-reload >/dev/null 2>&1 || true
fi

for item in \
  project-memory-common.md \
  save-work-checkpoint \
  resume-project-context \
  project-completed-summary \
  retro-summary \
  implementation-finder \
  project-autojournal
do
  rm -rf "$SKILLS_DIR/$item"
done

rm -f "$BIN_DIR/project-autojournal-run"

if [[ "$REMOVE_CONFIG" -eq 1 ]]; then
  rm -f "$CONFIG_FILE"
fi

echo "Uninstalled work skills."
