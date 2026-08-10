#!/usr/bin/env bash

set -euo pipefail

state_dir="${JIRA_STATE_DIR:-$HOME/git/daily/jira}"
cache_file="$state_dir/project-current.json"

if [[ ! -f "$cache_file" ]]; then
  printf 'JIRA --'
  exit 0
fi

timestamp="$(jq -r '.last_synced_at // empty' "$cache_file")"
if [[ -z "$timestamp" ]]; then
  printf 'JIRA --'
  exit 0
fi

epoch="$(date -d "$timestamp" +%s 2>/dev/null || true)"
if [[ -z "$epoch" ]]; then
  printf 'JIRA --'
  exit 0
fi

age=$(( $(date +%s) - epoch ))
(( age < 0 )) && age=0
if (( age < 60 )); then
  printf 'JIRA %ss' "$age"
elif (( age < 3600 )); then
  printf 'JIRA %sm' "$(( age / 60 ))"
elif (( age < 86400 )); then
  printf 'JIRA %sh' "$(( age / 3600 ))"
else
  printf 'JIRA %sd' "$(( age / 86400 ))"
fi
