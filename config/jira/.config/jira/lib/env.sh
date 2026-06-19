#!/usr/bin/env bash

[[ -f "$HOME/.config/local/jira.zsh" ]] && source "$HOME/.config/local/jira.zsh"

require_jira_project_key() {
  if [[ -z "${JIRA_PROJECT_KEY:-}" ]]; then
    echo "JIRA_PROJECT_KEY is not set" >&2
    echo "Set it in ~/.config/local/jira.zsh, for example:" >&2
    echo '  export JIRA_PROJECT_KEY="ABC"' >&2
    exit 1
  fi
}

require_jira_base_url() {
  if [[ -z "${JIRA_BASE_URL:-}" ]]; then
    echo "JIRA_BASE_URL is not set" >&2
    echo "Set it in ~/.config/local/jira.zsh, for example:" >&2
    echo '  export JIRA_BASE_URL="https://your-domain.atlassian.net"' >&2
    exit 1
  fi
}

jira_browse_url() {
  require_jira_base_url
  printf '%s/browse/%s\n' "${JIRA_BASE_URL%/}" "$1"
}

require_jira_board_url() {
  if [[ -z "${JIRA_BOARD_URL:-}" ]]; then
    echo "JIRA_BOARD_URL is not set" >&2
    echo "Set it in ~/.config/local/jira.zsh, for example:" >&2
    echo '  export JIRA_BOARD_URL="https://your-domain.atlassian.net/jira/software/..."' >&2
    exit 1
  fi
}
