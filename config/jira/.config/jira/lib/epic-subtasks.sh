#!/usr/bin/env bash

set -euo pipefail

lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$lib_dir/config.sh"
source "$lib_dir/views.sh"
source "$lib_dir/render.sh"
source "$lib_dir/status-render.sh"

usage() {
  cat <<'EOF'
Usage: jira epics <EPIC-KEY> subtasks <list|status> [--json]
EOF
}

epic_key="${1:-}"
action="${2:-}"
json=0

if [[ "$action" == list && "${3:-}" == --json ]]; then
  json=1
elif [[ -n "${3:-}" ]]; then
  echo "Unknown jira epics subtasks argument: $3" >&2
  usage >&2
  exit 1
fi

case "$action" in
  list|status) ;;
  *)
    echo "Unknown jira epics subtasks command: $action" >&2
    usage >&2
    exit 1
    ;;
esac

items_json="$(epic_subtasks_json "$epic_key")"

case "$action" in
  list)
    if (( json )); then
      printf '%s\n' "$items_json"
    else
      require_jira_base_url
      printf '%s\n' "$items_json" | render_issue_rows | while IFS=$'\t' read -r display _; do
        printf '%s\n' "$display"
      done
    fi
    ;;
  status)
    render_status_items "$items_json"
    ;;
esac
