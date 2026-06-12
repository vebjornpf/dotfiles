#!/usr/bin/env bash

set -euo pipefail

lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$lib_dir/env.sh"

state_dir="${JIRA_STATE_DIR:-$HOME/git/daily/jira}"
status_file="$state_dir/sync-status.json"

usage() {
  cat >&2 <<'EOF'
Usage: jira sync [mywork|backlog]

No arguments sync all supported targets.
EOF
}

ensure_state_dir() {
  mkdir -p "$state_dir"
}

ensure_status_file() {
  if [[ ! -f "$status_file" ]]; then
    printf '{\n  "last_attempt_at": null,\n  "last_sync_at": null,\n  "targets": {}\n}\n' >"$status_file"
  fi
}

write_completion_file() {
  local target="$1"
  local snapshot_file="$2"
  local completion_file

  completion_file="$state_dir/${target}-completion.tsv"

  jq -r '
    .[]
    | [(.key // ""), (.fields.status.name // ""), (.fields.summary // "")]
    | @tsv
  ' "$snapshot_file" >"$completion_file"
}

target_query() {
  case "$1" in
    mywork)
      printf '%s\n' 'assignee = currentUser() AND statusCategory != Done ORDER BY updated DESC'
      ;;
    backlog)
      require_jira_backlog_jql
      printf '%s\n' "$JIRA_BACKLOG_JQL"
      ;;
  esac
}

target_fields() {
  printf '%s\n' 'issuetype,key,assignee,reporter,priority,status,summary,description'
}

update_status_attempt() {
  local target="$1"
  local timestamp="$2"
  local query="$3"
  local tmpfile

  tmpfile="$(mktemp)"
  jq \
    --arg target "$target" \
    --arg timestamp "$timestamp" \
    --arg query "$query" \
    '
      .last_attempt_at = $timestamp
      | .targets = (.targets // {})
      | .targets[$target] = ((.targets[$target] // {}) + {
          last_attempt_at: $timestamp,
          query: $query,
          status: "running"
        })
    ' "$status_file" >"$tmpfile"
  mv "$tmpfile" "$status_file"
}

update_status_success() {
  local target="$1"
  local timestamp="$2"
  local query="$3"
  local count="$4"
  local tmpfile

  tmpfile="$(mktemp)"
  jq \
    --arg target "$target" \
    --arg timestamp "$timestamp" \
    --arg query "$query" \
    --argjson count "$count" \
    '
      .last_attempt_at = $timestamp
      | .last_sync_at = $timestamp
      | .targets = (.targets // {})
      | .targets[$target] = ((.targets[$target] // {}) + {
          last_attempt_at: $timestamp,
          last_sync_at: $timestamp,
          query: $query,
          status: "ok",
          count: $count,
          last_error: null
        })
    ' "$status_file" >"$tmpfile"
  mv "$tmpfile" "$status_file"
}

update_status_error() {
  local target="$1"
  local timestamp="$2"
  local query="$3"
  local error_message="$4"
  local tmpfile

  tmpfile="$(mktemp)"
  jq \
    --arg target "$target" \
    --arg timestamp "$timestamp" \
    --arg query "$query" \
    --arg error_message "$error_message" \
    '
      .last_attempt_at = $timestamp
      | .targets = (.targets // {})
      | .targets[$target] = ((.targets[$target] // {}) + {
          last_attempt_at: $timestamp,
          query: $query,
          status: "error",
          last_error: $error_message
        })
    ' "$status_file" >"$tmpfile"
  mv "$tmpfile" "$status_file"
}

sync_target() {
  local target="$1"
  local query fields current_file timestamp
  local tmpjson tmperr count error_message

  query="$(target_query "$target")"
  fields="$(target_fields)"
  current_file="$state_dir/${target}-current.json"
  timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

  update_status_attempt "$target" "$timestamp" "$query"

  tmpjson="$(mktemp)"
  tmperr="$(mktemp)"
  trap 'rm -f "${tmpjson:-}" "${tmperr:-}"' RETURN

  if acli jira workitem search --jql "$query" --fields "$fields" --paginate --json >"$tmpjson" 2>"$tmperr"; then
    count="$(jq 'length' "$tmpjson")"

    mv "$tmpjson" "$current_file"
    if [[ "$target" == "mywork" ]]; then
      write_completion_file "$target" "$current_file"
    fi
    update_status_success "$target" "$timestamp" "$query" "$count"
    printf 'Synced %s: %s items\n' "$target" "$count"
  else
    error_message="$(tr '\n' ' ' <"$tmperr" | sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//')"
    if [[ -z "$error_message" ]]; then
      error_message="acli jira workitem search failed"
    fi

    update_status_error "$target" "$timestamp" "$query" "$error_message"
    echo "Failed syncing $target: $error_message" >&2
    exit 1
  fi
}

main() {
  local targets=()
  local target

  ensure_state_dir
  ensure_status_file

  if (( $# == 0 )); then
    targets=(mywork)
    if has_jira_backlog_jql; then
      targets+=(backlog)
    fi
  else
    targets=("$@")
  fi

  for target in "${targets[@]}"; do
    case "$target" in
      mywork|backlog)
        ;;
      -h|--help|help)
        usage
        exit 0
        ;;
      *)
        usage
        echo "Unsupported jira sync target: $target" >&2
        exit 1
        ;;
    esac
  done

  for target in "${targets[@]}"; do
    sync_target "$target"
  done
}

main "$@"
