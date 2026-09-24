#!/usr/bin/env bash

set -euo pipefail

GHPR_HOME="${GHPR_HOME:-$HOME/.config/ghpr}"
target="${1:-mine}"
username="${2:-}"
policy="${3:-on-demand}"
tmux_sessionizer="$HOME/.config/tmux/scripts/tmux-sessionizer"
session="$(mktemp -d)"
trap 'rm -rf "$session"' EXIT

# Build shell-safe commands for fzf reload and preview actions.
printf -v list_cmd 'bash %q %q %q %q %q' "$GHPR_HOME/lib/session-list.sh" "$target" "$username" "$policy" "$session"
printf -v preview_cmd 'bash %q {2} {1} %q {3} {4} {5} {6} {7}' "$GHPR_HOME/lib/preview.sh" "$session"
printf -v fetch_cmd 'bash %q {2} {1} %q' "$GHPR_HOME/lib/fetch-detail.sh" "$session"
printf -v action_cmd 'bash %q' "$GHPR_HOME/lib/action.sh"

listfile="$session/list"
bash "$GHPR_HOME/lib/session-list.sh" "$target" "$username" "$policy" "$session" >"$listfile"

prompt="$target"
if [[ "$target" == user ]]; then
  prompt="$username"
fi

selected="$(fzf --ansi \
  --prompt="$prompt PRs > " \
  --delimiter=$'\t' --with-nth=8 --no-hscroll \
  --header=$'enter: open | alt-{o,c,a,v,m}: web/comment/approve/changes/merge\nalt-{p,d,u,k,y,r}: full preview/draft/update/checks/copy/reload' \
  --preview "$preview_cmd" \
  --preview-window='up:75%,wrap' \
  --bind "alt-r:reload($list_cmd)" \
  --bind "alt-p:execute($fetch_cmd {2} {1})+refresh-preview" \
  --bind "alt-o:execute-silent($action_cmd open {2} {1})" \
  --bind "alt-y:execute-silent($action_cmd copy {2} {1})" \
  --bind "alt-c:execute($action_cmd comment {2} {1})+reload($list_cmd)" \
  --bind "alt-a:execute($action_cmd approve {2} {1})+reload($list_cmd)" \
  --bind "alt-v:execute($action_cmd request-changes {2} {1})+reload($list_cmd)" \
  --bind "alt-m:execute($action_cmd merge {2} {1})+reload($list_cmd)" \
  --bind "alt-d:execute($action_cmd toggle-draft {2} {1})+reload($list_cmd)" \
  --bind "alt-u:execute($action_cmd update-branch {2} {1})+reload($list_cmd)" \
  --bind "alt-k:execute($action_cmd checks {2} {1})" <"$listfile")" || exit 0

[[ -n "$selected" ]] || exit 0

number="$(printf '%s' "$selected" | cut -f1)"
repo="$(printf '%s' "$selected" | cut -f2)"

if [[ "$target" == this ]]; then
  branch="$(gh pr view "$number" --repo "$repo" --json headRefName -q .headRefName)"
  exec bash "$GHPR_HOME/lib/open.sh" "$repo" "$number" "$branch"
fi

source "$GHPR_HOME/lib/common.sh"
ensure_repo_clone "$repo"
exec bash "$tmux_sessionizer" "$(repo_clone_path "$repo")"
