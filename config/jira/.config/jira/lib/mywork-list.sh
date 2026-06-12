#!/usr/bin/env bash

set -euo pipefail

state_dir="${JIRA_STATE_DIR:-$HOME/git/daily/jira}"
completion_file="$state_dir/mywork-completion.tsv"

if [[ ! -f "$completion_file" ]]; then
  exit 0
fi

while IFS=$'\t' read -r key status summary; do
  [[ -z "$key" ]] && continue
  printf '%-12s  %-16s  %s\n' "$key" "$status" "$summary"
done < "$completion_file"
