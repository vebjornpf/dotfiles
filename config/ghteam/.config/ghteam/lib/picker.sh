#!/usr/bin/env bash
set -euo pipefail

lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
org="$1"
state_dir="${GHTEAM_STATE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/ghteam}"
mkdir -p "$state_dir"
session="$(mktemp -d "$state_dir/session.XXXXXXXX")"
trap 'rm -rf "$session"' EXIT

bash "$lib_dir/list.sh" "$org" >"$session/teams"
if [[ ! -s "$session/teams" ]]; then
  printf 'ghteam: no teams visible in %s\n' "$org" >&2
  exit 0
fi

printf -v preview_command 'bash %q %q {1} %q' "$lib_dir/preview.sh" "$org" "$session"
selected="$(fzf --prompt="$org teams > " \
  --delimiter=$'\t' --with-nth=2 \
  --header='enter: open team | esc: exit' \
  --preview "$preview_command" \
  --preview-window='up:60%,wrap' <"$session/teams")" || {
  status=$?
  case "$status" in
    1|130) exit 0 ;;
    *) exit "$status" ;;
  esac
}

[[ -n "$selected" ]] || exit 0
slug="${selected%%$'\t'*}"
gh browse "https://github.com/orgs/$org/teams/$slug"
