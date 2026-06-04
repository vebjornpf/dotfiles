#!/usr/bin/env bash

set -euo pipefail

SCRIPTS_DIR="$(dirname "$0")"
cache_dir="$HOME/git/daily/prs-cache"
current_file="$cache_dir/assignedprs-current.json"
previous_file="$cache_dir/assignedprs-previous.json"
action="${1:-ensure}"

render() {
  if [[ -f "$previous_file" ]]; then
    bash "$SCRIPTS_DIR/assignedprs-grouped-render.sh" "$current_file" "$previous_file"
  else
    bash "$SCRIPTS_DIR/assignedprs-grouped-render.sh" "$current_file"
  fi
}

refresh_snapshot() {
  mkdir -p "$cache_dir"

  local tmpfile
  tmpfile="$(mktemp)"
  trap 'rm -f "$tmpfile"' RETURN

  bash "$SCRIPTS_DIR/assignedprs-grouped-json.sh" >"$tmpfile"

  if [[ -f "$current_file" ]]; then
    mv "$current_file" "$previous_file"
  fi

  mv "$tmpfile" "$current_file"
}

case "$action" in
  ensure)
    if [[ ! -f "$current_file" ]]; then
      refresh_snapshot
    fi
    render
    ;;
  refresh)
    refresh_snapshot
    render
    ;;
  *)
    echo "Usage: assignedprs-grouped-cache.sh [ensure|refresh]" >&2
    exit 1
    ;;
esac
