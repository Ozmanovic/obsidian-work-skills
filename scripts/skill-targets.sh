#!/usr/bin/env bash

work_skills_add_unique_dir() {
  local dir="$1"
  local existing

  for existing in "${WORK_SKILLS_RESOLVED_DIRS[@]}"; do
    [[ "$existing" == "$dir" ]] && return 0
  done

  WORK_SKILLS_RESOLVED_DIRS+=("$dir")
}

work_skills_add_agent_dirs() {
  local agent="$1"

  case "$agent" in
    all)
      work_skills_add_agent_dirs codex
      work_skills_add_agent_dirs claude
      work_skills_add_agent_dirs copilot
      ;;
    codex|openai|agents)
      work_skills_add_unique_dir "$HOME/.agents/skills"
      ;;
    claude|claude-code)
      work_skills_add_unique_dir "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills"
      ;;
    copilot|vscode)
      work_skills_add_unique_dir "$HOME/.copilot/skills"
      ;;
    "")
      ;;
    *)
      echo "Unknown agent target: $agent" >&2
      echo "Supported targets: all, codex, claude, copilot" >&2
      return 2
      ;;
  esac
}

work_skills_resolve_skill_dirs() {
  local agents="$1"
  shift || true
  local custom_dirs=("$@")
  local requested
  local agent

  WORK_SKILLS_RESOLVED_DIRS=()

  if [[ "${#custom_dirs[@]}" -gt 0 ]]; then
    for requested in "${custom_dirs[@]}"; do
      [[ -n "$requested" ]] && work_skills_add_unique_dir "$requested"
    done
    return 0
  fi

  IFS=',' read -r -a requested <<< "$agents"
  for agent in "${requested[@]}"; do
    agent="${agent//[[:space:]]/}"
    work_skills_add_agent_dirs "$agent"
  done
}
