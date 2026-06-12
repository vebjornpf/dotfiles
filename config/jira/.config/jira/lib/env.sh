#!/usr/bin/env bash

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

require_jira_backlog_jql() {
  if [[ -z "${JIRA_BACKLOG_JQL:-}" ]]; then
    echo "JIRA_BACKLOG_JQL is not set" >&2
    echo "Set it in ~/.config/local/jira.zsh, for example:" >&2
    echo "  export JIRA_BACKLOG_JQL='project = ABC AND status = Backlog ORDER BY created DESC'" >&2
    exit 1
  fi
}

has_jira_backlog_jql() {
  [[ -n "${JIRA_BACKLOG_JQL:-}" ]]
}
