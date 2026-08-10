#!/usr/bin/env bash

set -euo pipefail

lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$lib_dir/config.sh"
source "$lib_dir/views.sh"
source "$lib_dir/actions.sh"
source "$HOME/.config/zsh/lib/clipboard.sh"

key="${1:-}"
shift || true
action=""
transition_status=""
more=0
json=0

usage() {
  printf 'Usage: jira item <KEY> [assign|transition [STATUS]|open|cp|cpk|--more] [--json]\n'
}

case "$key" in
  -h|--help|help) usage; exit 0 ;;
  "") usage >&2; exit 1 ;;
esac
while (( $# > 0 )); do
  argument="$1"
  shift
  case "$argument" in
    assign|open|cp|cpk) action="$argument" ;;
    transition)
      action=transition
      if (( $# > 0 )) && [[ "$1" != --* ]]; then
        transition_status="$1"
        shift
      fi
      ;;
    --more) more=1 ;;
    --json) json=1 ;;
    -h|--help|help) usage; exit 0 ;;
    *) echo "Unknown jira item argument: $argument" >&2; usage >&2; exit 1 ;;
  esac
done

case "$action" in
  assign) assign_issue_to_me "$key"; exit 0 ;;
  transition)
    if [[ -n "$transition_status" ]]; then
      case "${transition_status,,}" in
        backlog) transition_issue_to_status "$key" "Backlog" ;;
        "in progress"|in-progress) transition_issue_to_status "$key" "In Progress" ;;
        qa) transition_issue_to_status "$key" "QA" ;;
        done) transition_issue_to_status "$key" "Done" ;;
        *) echo "Unknown transition: $transition_status. Valid: backlog, in progress, qa, done" >&2; exit 1 ;;
      esac
    else
      pick_and_transition_issue_status "$key"
    fi
    exit 0
    ;;
  open) exec acli jira workitem view "$key" --web ;;
  cp) jira_browse_url "$key" | clipboard_copy; exit 0 ;;
  cpk) printf '%s' "$key" | clipboard_copy; exit 0 ;;
esac

if (( more )); then
  if (( json )); then
    exec acli jira workitem view "$key" --json
  fi
  exec acli jira workitem view "$key"
fi

issue_json="$(cached_issue_json "$key" || true)"
[[ -n "$issue_json" ]] || { echo "Issue $key not found in project cache" >&2; exit 1; }
if (( json )); then
  printf '%s\n' "$issue_json"
else
  jq -r '"Key: \(.key // "")\nSummary: \(.fields.summary // "")\nStatus: \(.fields.status.name // "")\nAssignee: \(.fields.assignee.displayName // .fields.assignee.display_name // .fields.assignee.accountId // "Unassigned")\nReporter: \(.fields.reporter.displayName // .fields.reporter.display_name // .fields.reporter.accountId // "Unknown")\nPriority: \(.fields.priority.name // "")\nType: \(.fields.issuetype.name // "")\nUpdated: \(.fields.updated // "")"' <<<"$issue_json"
fi
