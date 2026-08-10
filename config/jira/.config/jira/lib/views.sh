#!/usr/bin/env bash

set -euo pipefail

lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$lib_dir/config.sh"
source "$lib_dir/state.sh"

epic_subtasks_json() {
  local epic_key="$1"
  local fields='key,summary,status,assignee,issuetype'

  acli jira workitem search \
    --jql "\"Epic Link\" = $epic_key" \
    --fields "$fields" \
    --paginate \
    --json
}

view_items_json() {
  local view="${1:-team}"
  require_project_cache

  case "$view" in
    team)
      project_items_json | jq '[.[] | select((.fields.assignee.accountId // .fields.assignee.account_id // "") != "")]'
      ;;
    backlog)
      project_items_json | jq '[.[] | select((.fields.status.name // "") == "Backlog")]'
      ;;
    epics)
      project_items_json | jq '[.[] | select((.fields.issuetype.name // "") == "Epic")]'
      ;;
    me)
      require_jira_account_id
      project_items_json | jq --arg account_id "$JIRA_ACCOUNT_ID" '[.[] | select((.fields.assignee.accountId // .fields.assignee.account_id // "") == $account_id)]'
      ;;
    *)
      echo "Unsupported Jira view: $view" >&2
      exit 1
      ;;
  esac
}

cached_issue_json() {
  local key="$1"
  require_project_cache
  jq --arg key "$key" '.items[]? | select((.key // "") == $key)' "$(state_cache_file)"
}
