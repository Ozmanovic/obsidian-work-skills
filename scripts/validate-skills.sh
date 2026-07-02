#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="$ROOT_DIR/skills"
STATUS=0

fail() {
  printf 'FAIL %s\n' "$*" >&2
  STATUS=1
}

required=(
  save-work-checkpoint
  resume-project-context
  project-completed-summary
  retro-summary
  implementation-finder
  project-autojournal
)

[[ -f "$SKILLS_DIR/project-memory-common.md" ]] || fail "Missing skills/project-memory-common.md"

for skill in "${required[@]}"; do
  skill_dir="$SKILLS_DIR/$skill"
  skill_file="$skill_dir/SKILL.md"
  ui_file="$skill_dir/agents/openai.yaml"

  [[ -d "$skill_dir" ]] || { fail "Missing skill dir: $skill"; continue; }
  [[ -f "$skill_file" ]] || { fail "Missing SKILL.md: $skill"; continue; }

  first_line="$(sed -n '1p' "$skill_file")"
  [[ "$first_line" == "---" ]] || fail "$skill SKILL.md missing opening frontmatter"
  rg -q "^name: $skill$" "$skill_file" || fail "$skill SKILL.md name mismatch"
  rg -q "^description: .+" "$skill_file" || fail "$skill SKILL.md missing description"

  if [[ -f "$ui_file" ]]; then
    rg -q "display_name:" "$ui_file" || fail "$skill openai.yaml missing display_name"
    rg -q "short_description:" "$ui_file" || fail "$skill openai.yaml missing short_description"
    rg -q "default_prompt: .+\\\$$skill" "$ui_file" || fail "$skill openai.yaml default_prompt should mention \$$skill"
    short_description="$(awk -F'"' '/short_description:/ {print $2}' "$ui_file")"
    if [[ "${#short_description}" -lt 25 || "${#short_description}" -gt 64 ]]; then
      fail "$skill short_description must be 25-64 chars"
    fi
  else
    fail "$skill missing agents/openai.yaml"
  fi
done

if rg -n '/home/wsluser|/mnt/c/OBSIDIAN/Work' "$SKILLS_DIR" >/dev/null; then
  rg -n '/home/wsluser|/mnt/c/OBSIDIAN/Work' "$SKILLS_DIR" >&2
  fail "Machine-specific paths found"
fi

exit "$STATUS"
