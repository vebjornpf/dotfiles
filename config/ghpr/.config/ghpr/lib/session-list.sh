#!/usr/bin/env bash

set -euo pipefail

GHPR_HOME="${GHPR_HOME:-$HOME/.config/ghpr}"
target="${1:-mine}"
username="${2:-}"
policy="${3:-on-demand}"
session="${4:?session directory required}"

listfile="$(mktemp "$session/.list.XXXXXXXX")"
trap 'rm -f "$listfile"' EXIT
bash "$GHPR_HOME/lib/picker-list.sh" "$target" "$username" >"$listfile"

# A reload starts a new generation of views; a failed query preserves the old one.
rm -rf "$session/details"

if [[ "$policy" == eager ]]; then
  count="$(wc -l <"$listfile")"
  if (( count > 0 )); then
    printf 'Fetching full views for %s PRs...\n' "$count" >&2
  fi
  pids=()
  failures=0
  while IFS=$'\t' read -r number repo _; do
    bash "$GHPR_HOME/lib/fetch-detail.sh" "$repo" "$number" "$session" &
    pids+=("$!")
    if (( ${#pids[@]} == 4 )); then
      for pid in "${pids[@]}"; do
        wait "$pid" || (( failures += 1 ))
      done
      pids=()
    fi
  done <"$listfile"
  for pid in "${pids[@]}"; do
    wait "$pid" || (( failures += 1 ))
  done
  if (( failures > 0 )); then
    printf '%s full views failed to load; their summaries remain available.\n' "$failures" >&2
  fi
fi

cat "$listfile"
