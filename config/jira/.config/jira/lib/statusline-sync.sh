#!/usr/bin/env bash

set -euo pipefail

state_dir="${JIRA_STATE_DIR:-$HOME/git/daily/jira}"
status_file="$state_dir/sync-status.json"

target_label() {
  case "$1" in
    mywork) printf 'MW' ;;
    backlog) printf 'BL' ;;
    *) printf '%s' "$1" ;;
  esac
}

timestamp_to_epoch() {
  local timestamp="$1"
  date -d "$timestamp" +%s 2>/dev/null || return 1
}

format_age() {
  local timestamp="$1"
  local now age

  now="$(date +%s)"
  age=$(( now - timestamp ))

  if (( age < 0 )); then
    age=0
  fi

  if (( age < 60 )); then
    printf '%ss' "$age"
  elif (( age < 3600 )); then
    printf '%sm' "$(( age / 60 ))"
  elif (( age < 86400 )); then
    printf '%sh' "$(( age / 3600 ))"
  else
    printf '%sd' "$(( age / 86400 ))"
  fi
}

render_target() {
  local target="$1"
  local label status timestamp epoch

  label="$(target_label "$target")"

  if [[ ! -f "$status_file" ]]; then
    printf '%s --' "$label"
    return
  fi

  status="$(jq -r --arg target "$target" '.targets[$target].status // empty' "$status_file")"

  if [[ "$status" == "error" ]]; then
    printf '%s !' "$label"
    return
  fi

  timestamp="$(jq -r --arg target "$target" '.targets[$target].last_sync_at // empty' "$status_file")"
  if [[ -z "$timestamp" ]]; then
    printf '%s --' "$label"
    return
  fi

  if ! epoch="$(timestamp_to_epoch "$timestamp")"; then
    printf '%s --' "$label"
    return
  fi

  printf '%s %s' "$label" "$(format_age "$epoch")"
}

main() {
  printf '%s %s' "$(render_target mywork)" "$(render_target backlog)"
}

main "$@"
