#!/usr/bin/env bash

set -euo pipefail

lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$lib_dir/env.sh"
source "$lib_dir/actions.sh"
source "$HOME/.config/zsh/lib/clipboard.sh"

key="${1:-}"
action="${2:-view}"
status_arg="${3:-}"
state_dir="${JIRA_STATE_DIR:-$HOME/git/daily/jira}"
url=""

usage() {
  cat >&2 <<'EOF'
Usage: jira item <KEY> [open|cp|cpk|print|move [backlog|in progress|qa|done]]
EOF
}

print_cached_issue() {
  local snapshot_file
  local -a snapshot_files=(
    "$state_dir/mywork-current.json"
    "$state_dir/all-current.json"
  )

  for snapshot_file in "${snapshot_files[@]}"; do
    [[ -f "$snapshot_file" ]] || continue

    if jq -e --arg key "$key" '.items[]? | select((.key // "") == $key)' "$snapshot_file" >/dev/null; then
      jq --arg key "$key" '.items[]? | select((.key // "") == $key)' "$snapshot_file"
      return 0
    fi
  done

  echo "Issue $key not found in cached Jira state" >&2
  exit 1
}

if [[ -z "$key" ]]; then
  usage
  exit 1
fi

case "$action" in
  view)
    acli jira workitem view "$key"
    ;;
  open)
    acli jira workitem view "$key" --web
    ;;
  cp)
    url="$(jira_browse_url "$key")"
    printf '%s' "$url" | clipboard_copy
    ;;
  cpk)
    printf '%s' "$key" | clipboard_copy
    ;;
  print)
    print_cached_issue
    ;;
  move)
    if [[ -n "$status_arg" ]]; then
      case "${status_arg,,}" in
        backlog)       transition_issue_to_status "$key" "Backlog" ;;
        "in progress") transition_issue_to_status "$key" "In Progress" ;;
        qa)            transition_issue_to_status "$key" "QA" ;;
        done)          transition_issue_to_status "$key" "Done" ;;
        *)
          echo "Unknown status: $status_arg. Valid: backlog, in progress, qa, done" >&2
          exit 1
          ;;
      esac
    else
      pick_and_transition_issue_status "$key"
    fi
    ;;
  *)
    usage
    echo "Unsupported jira item action: $action" >&2
    exit 1
    ;;
esac
