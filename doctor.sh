#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${PROJECT_MEMORY_CONFIG:-$HOME/.agents/project-memory.env}"
AGENTS="${WORK_SKILLS_AGENTS:-all}"
CUSTOM_SKILLS_DIRS=()
STATUS=0

if [[ -n "${WORK_SKILLS_SKILLS_DIR:-}" ]]; then
  CUSTOM_SKILLS_DIRS+=("$WORK_SKILLS_SKILLS_DIR")
fi

ok() { printf 'OK   %s\n' "$*"; }
info() { printf 'INFO %s\n' "$*"; }
warn() { printf 'WARN %s\n' "$*"; }
fail() { printf 'FAIL %s\n' "$*"; STATUS=1; }

usage() {
  cat <<'EOF'
Usage: ./doctor.sh [options]

Options:
  --agents LIST      Comma-separated: all,codex,claude,copilot. Default: all
  --skills-dir PATH  Check a custom skill PATH. Can be repeated.
  --config PATH      Config file path. Default: ~/.agents/project-memory.env
  -h, --help         Show help.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --agents) AGENTS="$2"; shift 2 ;;
    --skills-dir) CUSTOM_SKILLS_DIRS+=("$2"); shift 2 ;;
    --config) CONFIG_FILE="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done

# shellcheck source=scripts/skill-targets.sh
. "$ROOT_DIR/scripts/skill-targets.sh"
work_skills_resolve_skill_dirs "$AGENTS" "${CUSTOM_SKILLS_DIRS[@]}"

if [[ -f "$CONFIG_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  . "$CONFIG_FILE"
  set +a
  ok "Config found: $CONFIG_FILE"
else
  fail "Config missing: $CONFIG_FILE"
fi

VAULT="${PROJECT_MEMORY_VAULT:-}"
WORK_ROOT="${PROJECT_MEMORY_WORK_ROOT:-Work}"
REPO_ROOTS="${PROJECT_MEMORY_REPO_ROOTS:-$HOME/git}"
TIMEZONE="${PROJECT_MEMORY_TIMEZONE:-UTC}"
AGENT_SOURCES="${PROJECT_MEMORY_AGENT_SOURCES:-codex,claude,copilot}"

if [[ -n "$VAULT" && -d "$VAULT" ]]; then
  ok "Vault found: $VAULT"
  if [[ -d "$VAULT/.obsidian" ]]; then
    ok "Obsidian vault marker found: $VAULT/.obsidian"
  else
    warn "No .obsidian folder found under vault path. Notes can still be written, but confirm this is the intended Obsidian vault."
  fi
  mkdir -p "$VAULT/$WORK_ROOT"
  test_file="$VAULT/$WORK_ROOT/.work-skills-write-test"
  if : > "$test_file" 2>/dev/null; then
    rm -f "$test_file"
    ok "Work folder writable: $VAULT/$WORK_ROOT"
  else
    fail "Work folder not writable: $VAULT/$WORK_ROOT"
  fi
else
  fail "Vault not found. Set PROJECT_MEMORY_VAULT in $CONFIG_FILE"
fi

for skills_dir in "${WORK_SKILLS_RESOLVED_DIRS[@]}"; do
  for item in \
    project-memory-common.md \
    setup-obsidian-work-skills \
    save-work-checkpoint \
    resume-project-context \
    project-completed-summary \
    retro-summary \
    implementation-finder \
    project-autojournal
  do
    if [[ -e "$skills_dir/$item" ]]; then
      ok "Installed in $skills_dir: $item"
    else
      fail "Missing installed skill: $skills_dir/$item"
    fi
  done
done

if command -v rg >/dev/null 2>&1; then
  ok "rg found: $(command -v rg)"
else
  warn "rg not found. Searches will fall back to slower grep/find/git grep where possible."
fi

if command -v git >/dev/null 2>&1; then
  ok "git found: $(command -v git)"
else
  warn "git not found. Obsidian notes still work, but repo facts, diffs, commits, and implementation search will be limited."
fi

if command -v obsidian >/dev/null 2>&1; then
  info "Obsidian command found: $(command -v obsidian)"
else
  info "Obsidian command not found. Not required; work skills write Markdown files directly to the vault folder."
fi

if command -v codex >/dev/null 2>&1; then
  ok "Codex CLI found: $(command -v codex)"
else
  warn "Codex CLI not found. Manual skills may still work in supported agents, optional Codex-powered autojournal runner will not."
fi

IFS=':' read -r -a repo_roots <<< "$REPO_ROOTS"
found_repo_root=0
for root in "${repo_roots[@]}"; do
  expanded="${root/#\~/$HOME}"
  if [[ -d "$expanded" ]]; then
    ok "Repo root found: $expanded"
    found_repo_root=1
  else
    warn "Repo root missing: $expanded"
  fi
done
if [[ "$found_repo_root" -eq 0 ]]; then
  warn "No configured repo roots found"
fi

IFS=',' read -r -a sources <<< "$AGENT_SOURCES"
for source in "${sources[@]}"; do
  case "$source" in
    codex)
      codex_root="${PROJECT_MEMORY_CODEX_SESSIONS:-${CODEX_HOME:-$HOME/.codex}/sessions}"
      [[ -d "$codex_root" ]] && ok "Codex sessions readable: $codex_root" || warn "Codex sessions not found: $codex_root"
      ;;
    claude)
      claude_root="${PROJECT_MEMORY_CLAUDE_PROJECTS:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects}"
      [[ -d "$claude_root" ]] && ok "Claude sessions readable: $claude_root" || warn "Claude sessions not found: $claude_root"
      ;;
    copilot)
      copilot_ws="${PROJECT_MEMORY_COPILOT_WORKSPACE_STORAGE:-$HOME/.vscode-server/data/User/workspaceStorage}"
      copilot_global="${PROJECT_MEMORY_COPILOT_GLOBAL_STORAGE:-$HOME/.vscode-server/data/User/globalStorage/github.copilot-chat}"
      if compgen -G "$copilot_ws/*/GitHub.copilot-chat/transcripts/*.jsonl" >/dev/null || [[ -f "$copilot_global/session-store.db" ]]; then
        ok "Copilot sources found"
      else
        warn "Copilot sources not found"
      fi
      ;;
    "") ;;
    *) warn "Unknown agent source: $source" ;;
  esac
done

if command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then
  if systemctl --user list-unit-files project-autojournal.timer >/dev/null 2>&1; then
    timer_state="$(systemctl --user is-enabled project-autojournal.timer 2>/dev/null || true)"
    ok "systemd user timer available: project-autojournal.timer ${timer_state:-not installed}"
    systemctl --user list-timers project-autojournal.timer --no-pager 2>/dev/null || true
  else
    ok "systemd user available; autojournal timer not installed"
  fi
else
  warn "systemd user timers unavailable on this machine"
fi

"$ROOT_DIR/scripts/validate-skills.sh" >/dev/null && ok "Packaged skills validate" || fail "Packaged skills failed validation"

if [[ "$STATUS" -eq 0 ]]; then
  echo
  echo "Ready."
else
  echo
  echo "Not ready. Fix FAIL items above."
fi

exit "$STATUS"
