#!/usr/bin/env bash

set -euo pipefail

GHPR_HOME="${GHPR_HOME:-$HOME/.config/ghpr}"
target="${1:-mine}"
username="${2:-}"

columns="${COLUMNS:-120}"
if [[ -t 1 ]] && command -v tput >/dev/null 2>&1; then
  columns="$(tput cols 2>/dev/null || printf '120')"
fi

truncate() {
  local value="${1:-}"
  local width="${2:-20}"

  if (( ${#value} > width )); then
    printf '%s...' "${value:0:width-3}"
  else
    printf '%s' "$value"
  fi
}

case "$target" in
  mine|user|this)
    title_width=$((columns - 55))
    ;;
  team)
    title_width=$((columns - 76))
    ;;
  *)
    title_width=$((columns - 55))
    ;;
esac

if (( title_width < 24 )); then
  title_width=24
fi

rows="$(bash "$GHPR_HOME/lib/query.sh" "$target" "$username")"

case "$target" in
  mine|user)
    printf '%-7s %-26s %-10s %-7s %s\n' PR REPOSITORY UPDATED STATE TITLE
    ;;
  this)
    printf '%-7s %-20s %-10s %-7s %s\n' PR AUTHOR UPDATED STATE TITLE
    ;;
  team)
    printf '%-7s %-26s %-20s %-10s %-7s %s\n' PR REPOSITORY AUTHOR UPDATED STATE TITLE
    ;;
  *)
    printf '%-7s %-26s %-10s %-7s %s\n' PR REPOSITORY UPDATED STATE TITLE
    ;;
esac

printf '%s\n' "$rows" |
  while IFS=$'\t' read -r number repo author updated state title url; do
    repo_name="${repo#*/}"
    updated="${updated%%T*}"
    state="${state^^}"
    repo_name="$(truncate "$repo_name" 26)"
    author="$(truncate "$author" 20)"
    title="$(truncate "$title" "$title_width")"

    case "$target" in
      mine|user)
        printf '#%-6s %-26s %-10s %-7s %s\n' "$number" "$repo_name" "$updated" "$state" "$title"
        ;;
      this)
        printf '#%-6s %-20s %-10s %-7s %s\n' "$number" "$author" "$updated" "$state" "$title"
        ;;
      team)
        printf '#%-6s %-26s %-20s %-10s %-7s %s\n' "$number" "$repo_name" "$author" "$updated" "$state" "$title"
        ;;
      *)
        printf '#%-6s %-26s %-10s %-7s %s\n' "$number" "$repo_name" "$updated" "$state" "$title"
        ;;
    esac
  done
