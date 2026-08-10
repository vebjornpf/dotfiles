#!/usr/bin/env bash

set -euo pipefail

lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$lib_dir/config.sh"

usage() {
  printf 'Usage: jira sync\n'
}

if (( $# > 0 )); then
  case "$1" in
    -h|--help|help) usage; exit 0 ;;
    *) echo "jira sync takes no arguments" >&2; usage >&2; exit 1 ;;
  esac
fi

require_jira_project_key
mkdir -p "$JIRA_STATE_DIR"

query="project = $JIRA_PROJECT_KEY AND statusCategory != Done ORDER BY updated DESC"
# acli's search command only accepts these summary fields. Components and
# updated are not valid --fields values in the installed acli version.
fields='key,summary,description,status,assignee,reporter,priority,issuetype'
cache_tmp="$(mktemp)"
error_tmp="$(mktemp)"
trap 'rm -f "$cache_tmp" "$error_tmp"' EXIT

if ! acli jira workitem search --jql "$query" --fields "$fields" --paginate --json >"$cache_tmp" 2>"$error_tmp"; then
  error_message="$(tr '\n' ' ' <"$error_tmp" | sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//')"
  [[ -n "$error_message" ]] || error_message='acli jira workitem search failed'
  echo "Failed syncing Jira project: $error_message" >&2
  exit 1
fi

timestamp="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
jq -n --arg timestamp "$timestamp" --arg query "$query" --slurpfile items "$cache_tmp" '{last_synced_at: $timestamp, query: $query, count: ($items[0] | length), items: $items[0]}' >"$JIRA_STATE_DIR/project-current.json"

jq -r '.items[]? | select((.fields.assignee.accountId // .fields.assignee.account_id // "") != "") | [(.key // ""), (.fields.status.name // ""), (.fields.summary // "")] | @tsv' "$JIRA_STATE_DIR/project-current.json" >"$JIRA_STATE_DIR/team-completion.tsv"
if [[ -n "${JIRA_ACCOUNT_ID:-}" ]]; then
  jq --arg account_id "$JIRA_ACCOUNT_ID" -r '.items[]? | select((.fields.assignee.accountId // .fields.assignee.account_id // "") == $account_id) | [(.key // ""), (.fields.status.name // ""), (.fields.summary // "")] | @tsv' "$JIRA_STATE_DIR/project-current.json" >"$JIRA_STATE_DIR/me-completion.tsv"
else
  : >"$JIRA_STATE_DIR/me-completion.tsv"
fi
jq -r '.items[]? | select((.fields.status.name // "") == "Backlog") | [(.key // ""), (.fields.status.name // ""), (.fields.summary // "")] | @tsv' "$JIRA_STATE_DIR/project-current.json" >"$JIRA_STATE_DIR/backlog-completion.tsv"
jq -r '.items[]? | select((.fields.issuetype.name // "") == "Epic") | [(.key // ""), (.fields.status.name // ""), (.fields.summary // "")] | @tsv' "$JIRA_STATE_DIR/project-current.json" >"$JIRA_STATE_DIR/epics-completion.tsv"
printf 'Synced Jira project: %s items\n' "$(jq -r '.count' "$JIRA_STATE_DIR/project-current.json")"
