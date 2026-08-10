#!/usr/bin/env bash

set -euo pipefail

render_status_items() {
  local items_json="$1"
  local current_status=""
  local reset=""
  local bold=""

  if [[ -t 1 ]]; then
    reset=$'\033[0m'
    bold=$'\033[1m'
  fi

  status_color() {
    if [[ -z "$bold" ]]; then
      printf ''
      return
    fi

    case "$1" in
      Backlog) printf '\033[1;34m' ;;
      Selected) printf '\033[1;36m' ;;
      "In Progress"|"In progress") printf '\033[1;33m' ;;
      QA|Review) printf '\033[1;35m' ;;
      Paused) printf '\033[1;31m' ;;
      Triage) printf '\033[1;32m' ;;
      Done) printf '\033[1;32m' ;;
      *) printf '%s' "$bold" ;;
    esac
  }

  while IFS=$'\t' read -r issue_status key assignee summary; do
    if [[ "$issue_status" != "$current_status" ]]; then
      [[ -n "$current_status" ]] && printf '\n'
      printf '%s%s%s%s\n' "$(status_color "$issue_status")" "$bold" "$issue_status" "$reset"
      current_status="$issue_status"
    fi
    printf '%-12s  %-24s  %s\n' "$key" "$assignee" "$summary"
  done < <(
    jq -r --argjson ordered '["Backlog", "Selected", "In Progress", "In progress", "Blocked", "QA", "Review", "Done"]' '
      [.[] | {
        status: (.fields.status.name // "Unknown"),
        key: (.key // ""),
        assignee: (.fields.assignee.displayName // .fields.assignee.display_name // .fields.assignee.accountId // "Unassigned"),
        summary: (.fields.summary // "")
      } | .status as $status | .rank = (($ordered | index($status)) // 999)]
      | sort_by(.rank, .status, .key)
      | .[]
      | [.status, .key, .assignee, .summary]
      | @tsv
    ' <<<"$items_json"
  )
}
