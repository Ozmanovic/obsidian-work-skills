#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${PROJECT_MEMORY_CONFIG:-$HOME/.agents/project-memory.env}"
TIMER_TIME="${PROJECT_MEMORY_AUTOJOURNAL_TIME:-15:30}"
ENABLE=0
YES=0

usage() {
  cat <<'EOF'
Usage: scripts/install-autojournal-timer.sh [options]

Options:
  --config PATH       Config file path. Default: ~/.agents/project-memory.env
  --timer-time HH:MM  Daily run time. Default: config or 15:30
  --enable           Enable timer immediately
  -y, --yes          Do not prompt
  -h, --help         Show help
EOF
}

unit_escape() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  printf '%s' "$value"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --config) CONFIG_FILE="$2"; shift 2 ;;
    --timer-time) TIMER_TIME="$2"; shift 2 ;;
    --enable) ENABLE=1; shift ;;
    -y|--yes) YES=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done

if [[ -f "$CONFIG_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  . "$CONFIG_FILE"
  set +a
  TIMER_TIME="${PROJECT_MEMORY_AUTOJOURNAL_TIME:-$TIMER_TIME}"
fi

if ! command -v systemctl >/dev/null 2>&1 || ! systemctl --user show-environment >/dev/null 2>&1; then
  echo "systemd user timers are not available on this machine." >&2
  exit 1
fi

runner="$HOME/.local/bin/project-autojournal-run"
if [[ ! -x "$runner" ]]; then
  echo "Runner not found or not executable: $runner" >&2
  echo "Run ./install.sh first." >&2
  exit 1
fi

if [[ "$YES" -eq 0 ]]; then
  cat <<EOF
Optional autojournal timer

This creates a user-level systemd timer. It runs Codex CLI once per day.

May read:
- local Codex/Claude/Copilot session files
- git repo metadata/diffs when needed
- existing Obsidian project notes

May write:
- Obsidian checkpoint notes
- project-autojournal state/log files

Will not:
- edit source code
- commit, push, or deploy
- create productivity reports

Install timer for $TIMER_TIME? [y/N]
EOF
  read -r answer
  case "$answer" in
    y|Y|yes|YES) ;;
    *) echo "Timer not installed."; exit 0 ;;
  esac
fi

systemd_dir="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
mkdir -p "$systemd_dir"

cat > "$systemd_dir/project-autojournal.service" <<EOF
[Unit]
Description=Work Skills project autojournal

[Service]
Type=oneshot
Environment="PROJECT_MEMORY_CONFIG=$(unit_escape "$CONFIG_FILE")"
ExecStart="$(unit_escape "$runner")"
EOF

cat > "$systemd_dir/project-autojournal.timer" <<EOF
[Unit]
Description=Run Work Skills project autojournal daily

[Timer]
OnCalendar=*-*-* $TIMER_TIME:00
Persistent=true
Unit=project-autojournal.service

[Install]
WantedBy=timers.target
EOF

systemctl --user daemon-reload

if [[ "$ENABLE" -eq 1 ]]; then
  systemctl --user enable --now project-autojournal.timer
  systemctl --user list-timers project-autojournal.timer --no-pager
else
  echo "Timer installed but not enabled."
  echo "Enable with:"
  echo "  systemctl --user enable --now project-autojournal.timer"
fi

echo "Disable with:"
echo "  systemctl --user disable --now project-autojournal.timer"
