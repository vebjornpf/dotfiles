#!/usr/bin/env bash

set -euo pipefail

lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$lib_dir/env.sh"

state_dir="${JIRA_STATE_DIR:-$HOME/git/daily/jira}"
status_file="$state_dir/sync-status.json"

usage() {
  cat >&2 <<'EOF'
Usage: jira sync [all|mywork]

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

target_state_file() {
  printf '%s/%s-current.json\n' "$state_dir" "$1"
}

target_query() {
  case "$1" in
    all)
      require_jira_project_key
      printf '%s\n' "project = $JIRA_PROJECT_KEY AND statusCategory != Done AND (assignee != currentUser() OR assignee is EMPTY) ORDER BY updated DESC"
      ;;
    mywork)
      printf '%s\n' 'assignee = currentUser() AND statusCategory != Done ORDER BY updated DESC'
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

write_completion_from_file() {
  local source_file="$1"
  local output_file="$2"
  local filter="$3"

  if [[ ! -f "$source_file" ]]; then
    : >"$output_file"
    return
  fi

  jq -r "$filter" "$source_file" >"$output_file"
}

write_all_completion_file() {
  local output_file="$state_dir/all-completion.tsv"
  local all_file mywork_file
  local -a source_files=()

  all_file="$(target_state_file all)"
  mywork_file="$(target_state_file mywork)"

  [[ -f "$all_file" ]] && source_files+=("$all_file")
  [[ -f "$mywork_file" ]] && source_files+=("$mywork_file")

  if (( ${#source_files[@]} == 0 )); then
    : >"$output_file"
    return
  fi

  jq -s -r '
    [.[].items[]?]
    | .[]
    | [(.key // ""), (.fields.status.name // ""), (.fields.summary // "")]
    | @tsv
  ' "${source_files[@]}" >"$output_file"
}

write_derived_files() {
  local all_file mywork_file

  all_file="$(target_state_file all)"
  mywork_file="$(target_state_file mywork)"

  write_completion_from_file \
    "$mywork_file" \
    "$state_dir/mywork-completion.tsv" \
    '.items[]? | [(.key // ""), (.fields.status.name // ""), (.fields.summary // "")] | @tsv'

  write_completion_from_file \
    "$all_file" \
    "$state_dir/backlog-completion.tsv" \
    '.items[]? | select((.fields.status.name // "") == "Backlog") | [(.key // ""), (.fields.status.name // ""), (.fields.summary // "")] | @tsv'

  write_completion_from_file \
    "$all_file" \
    "$state_dir/epics-completion.tsv" \
    '.items[]? | select((.fields.issuetype.name // "") == "Epic") | [(.key // ""), (.fields.status.name // ""), (.fields.summary // "")] | @tsv'

  write_all_completion_file
}

sync_target() {
  local target="$1"
  local query fields current_file timestamp
  local tmpjson tmperr tmpstate count error_message

  query="$(target_query "$target")"
  fields="$(target_fields)"
  current_file="$(target_state_file "$target")"
  timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

  update_status_attempt "$target" "$timestamp" "$query"

  tmpjson="$(mktemp)"
  tmperr="$(mktemp)"
  tmpstate="$(mktemp)"
  trap 'rm -f "${tmpjson:-}" "${tmperr:-}" "${tmpstate:-}"' RETURN

  if acli jira workitem search --jql "$query" --fields "$fields" --paginate --json >"$tmpjson" 2>"$tmperr"; then
    count="$(jq 'length' "$tmpjson")"

    jq -n \
      --arg last_synced_at "$timestamp" \
      --arg query "$query" \
      --slurpfile items "$tmpjson" \
      '{
        last_synced_at: $last_synced_at,
        query: $query,
        count: ($items[0] | length),
        items: $items[0]
      }' >"$tmpstate"

    mv "$tmpstate" "$current_file"
    write_derived_files
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
    targets=(all mywork)
  else
    targets=("$@")
  fi

  for target in "${targets[@]}"; do
    case "$target" in
      all|mywork)
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
