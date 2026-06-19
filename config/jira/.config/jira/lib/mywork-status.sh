#!/usr/bin/env bash

set -euo pipefail

state_dir="${JIRA_STATE_DIR:-$HOME/git/daily/jira}"
snapshot_file="$state_dir/mywork-current.json"

if [[ ! -f "$snapshot_file" ]]; then
  exit 0
fi

status_color() {
  case "$1" in
    Backlog) printf '\033[34m' ;;
    Selected) printf '\033[36m' ;;
    "In Progress"|"In progress") printf '\033[33m' ;;
    Blocked) printf '\033[31m' ;;
    Review|QA) printf '\033[35m' ;;
    Done) printf '\033[32m' ;;
    *) printf '\033[37m' ;;
  esac
}

print_section() {
  local status_name="$1"
  local issues_json="$2"
  local color reset

  [[ "$issues_json" == "[]" ]] && return 0

  color="$(status_color "$status_name")"
  reset='\033[0m'

  printf '\n'
  printf '%b%s%b\n' "$color" "$status_name" "$reset"
  jq -r '.[] | "\(.key // "")  \(.fields.summary // "")"' <<<"$issues_json"
}

ordered_statuses=(
  "Backlog"
  "Selected"
  "In progress"
  "Blocked"
  "QA"
  "Review"
  "Done"
)

all_statuses_json="$(jq -r '.items | map(.fields.status.name // "Unknown") | unique | .[]' "$snapshot_file")"

for status_name in "${ordered_statuses[@]}"; do
  issues_json="$(jq --arg status "$status_name" '[.items[] | select((.fields.status.name // "Unknown") == $status)]' "$snapshot_file")"
  print_section "$status_name" "$issues_json"
done

while IFS= read -r status_name; do
  [[ -z "$status_name" ]] && continue

  case " $* ${ordered_statuses[*]} " in
    *" $status_name "*)
      continue
      ;;
  esac

  issues_json="$(jq --arg status "$status_name" '[.items[] | select((.fields.status.name // "Unknown") == $status)]' "$snapshot_file")"
  print_section "$status_name" "$issues_json"
done <<<"$all_statuses_json"
