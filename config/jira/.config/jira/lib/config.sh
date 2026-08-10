#!/usr/bin/env bash

set -euo pipefail

JIRA_HOME="${JIRA_HOME:-$HOME/.config/jira}"
source "$JIRA_HOME/lib/env.sh"

JIRA_STATE_DIR="${JIRA_STATE_DIR:-$HOME/git/daily/jira}"
JIRA_CACHE_FILE="$JIRA_STATE_DIR/project-current.json"

require_jira_account_id() {
  if [[ -z "${JIRA_ACCOUNT_ID:-}" ]]; then
    echo "JIRA_ACCOUNT_ID is not set" >&2
    echo "Set it in ~/.config/local/tools.zsh" >&2
    exit 1
  fi
}
