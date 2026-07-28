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

# The config may name several slots a day. Honour the plural first and fall back to the
# singular, otherwise a machine configured for 15:30,18:30,22:30 silently gets one run.
TIMER_TIMES="${PROJECT_MEMORY_AUTOJOURNAL_TIMES:-$TIMER_TIME}"
IFS=',' read -r -a timer_slots <<< "$TIMER_TIMES"
for i in "${!timer_slots[@]}"; do
  slot="${timer_slots[$i]//[[:space:]]/}"
  if [[ ! "$slot" =~ ^([01][0-9]|2[0-3]):[0-5][0-9]$ ]]; then
    echo "Invalid autojournal time: '$slot' (expected HH:MM)" >&2
    exit 2
  fi
  timer_slots[$i]="$slot"
done

# systemd user timers are the preferred mechanism, but plenty of machines do not have a user
# bus at all -- WSL being the common one. Falling through to cron keeps those installs
# scheduled instead of leaving them with no timer and no warning.
SCHEDULER=""
if command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then
  SCHEDULER="systemd"
elif command -v crontab >/dev/null 2>&1; then
  SCHEDULER="cron"
else
  echo "No supported scheduler found: neither systemd user timers nor crontab." >&2
  echo "On Windows/WSL, schedule $HOME/.local/bin/project-autojournal-run from Windows Task" >&2
  echo "Scheduler instead, with 'Run task as soon as possible after a scheduled start is missed'." >&2
  exit 1
fi

runner="$HOME/.local/bin/project-autojournal-run"
if [[ ! -x "$runner" ]]; then
  echo "Runner not found or not executable: $runner" >&2
  echo "Run ./install.sh from a cloned work-skills repo first. Normal npx skills installs do not install the scheduled runner." >&2
  exit 1
fi

if [[ "$YES" -eq 0 ]]; then
  cat <<EOF
Optional autojournal timer

This creates a $SCHEDULER schedule. The runner uses Codex CLI once per configured slot.

May read:
- local Codex/Claude/Copilot session files
- git repo metadata/diffs when needed
- existing Obsidian project notes

May write:
- Obsidian checkpoint notes
- project-autojournal state/log files

Will not:
- edit source/work files
- commit, push, or deploy
- create productivity reports

Install $SCHEDULER schedule for ${timer_slots[*]}? [y/N]
EOF
  read -r answer
  case "$answer" in
    y|Y|yes|YES) ;;
    *) echo "Timer not installed."; exit 0 ;;
  esac
fi

if [[ "$SCHEDULER" == "cron" ]]; then
  marker_begin="# BEGIN project-autojournal (managed by obsidian-work-skills)"
  marker_end="# END project-autojournal (managed by obsidian-work-skills)"
  existing="$(crontab -l 2>/dev/null || true)"
  # Drop any previous managed block so repeated installs replace rather than accumulate.
  cleaned="$(printf '%s\n' "$existing" | awk -v b="$marker_begin" -v e="$marker_end" '
    $0 == b { skip = 1 } skip == 0 { print } $0 == e { skip = 0 }')"
  {
    printf '%s\n' "$cleaned"
    printf '%s\n' "$marker_begin"
    for slot in "${timer_slots[@]}"; do
      printf '%s %s * * * PROJECT_MEMORY_CONFIG=%q %q\n' \
        "${slot#*:}" "${slot%:*}" "$CONFIG_FILE" "$runner"
    done
    printf '%s\n' "$marker_end"
  } | crontab -

  echo "Installed cron entries for: ${timer_slots[*]}"
  echo "Note: cron does not catch up a slot missed while the machine was off."
  echo "Remove with: crontab -e  (delete the managed project-autojournal block)"
  exit 0
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

{
  printf '[Unit]\n'
  printf 'Description=Run Work Skills project autojournal\n\n'
  printf '[Timer]\n'
  for slot in "${timer_slots[@]}"; do
    printf 'OnCalendar=*-*-* %s:00\n' "$slot"
  done
  # Persistent runs a slot that was missed while the machine was off.
  printf 'Persistent=true\n'
  printf 'Unit=project-autojournal.service\n\n'
  printf '[Install]\n'
  printf 'WantedBy=timers.target\n'
} > "$systemd_dir/project-autojournal.timer"

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
