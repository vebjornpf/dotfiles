#!/usr/bin/env bash

set -euo pipefail

lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$lib_dir/actions.sh"

usage() {
  cat >&2 <<'EOF'
Usage: action.sh <assign-me|transition> <KEY> [status]
EOF
}

action="${1:-}"
key="${2:-}"

if [[ -z "$action" || -z "$key" ]]; then
  usage
  exit 1
fi

case "$action" in
  assign-me)
    assign_issue_to_me "$key"
    ;;
  transition)
    status="${3:-}"
    [[ -n "$status" ]] || { usage; exit 1; }
    transition_issue_to_status "$key" "$status"
    ;;
  *)
    usage
    echo "Unsupported jira action: $action" >&2
    exit 1
    ;;
esac
