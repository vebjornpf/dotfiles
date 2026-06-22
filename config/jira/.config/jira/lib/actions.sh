#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"

assign_issue_to_me() {
  local key="$1"

  acli jira workitem assign --key "$key" --assignee @me --yes
}

transition_issue_to_status() {
  local key="$1"
  local status="$2"

  acli jira workitem transition --key "$key" --status "$status" --yes
}

hardcoded_statuses=(Backlog "In Progress" QA Done)

pick_and_transition_issue_status() {
  local key="$1"
  local status

  status="$(printf '%s\n' "${hardcoded_statuses[@]}" | fzf --prompt='Status > ' --height=40% --layout=reverse)" || return 1
  [[ -n "$status" ]] || return 1
  transition_issue_to_status "$key" "$status"
}
