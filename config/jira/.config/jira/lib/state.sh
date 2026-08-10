#!/usr/bin/env bash

set -euo pipefail

state_cache_file() {
  printf '%s/project-current.json\n' "${JIRA_STATE_DIR:-$HOME/git/daily/jira}"
}

require_project_cache() {
  local cache_file
  cache_file="$(state_cache_file)"
  if [[ ! -f "$cache_file" ]]; then
    echo "No Jira project cache exists. Run 'jira sync'." >&2
    exit 1
  fi
}

project_items_json() {
  jq '.items // []' "$(state_cache_file)"
}
