#!/usr/bin/env bash

repo_full="${1:-}"
pr_number="${2:-}"
branch="${3:-}"

if [[ -z "$pr_number" ]]; then
  echo "Usage: ghpr-open.sh [org/repo] <pr_number> [branch]" >&2
  exit 1
fi

# Derive repo from git remote if not passed
if [[ -z "$repo_full" ]]; then
  remote=$(git remote get-url origin 2>/dev/null) || { echo "Not a git repo and no repo arg provided." >&2; exit 1; }
  repo_full=$(echo "$remote" | sed 's|.*github.com[:/]\(.*\)\.git|\1|' | sed 's|.*github.com[:/]\(.*\)|\1|')
fi

repo_short="${repo_full##*/}"
clone_path="$HOME/git/$repo_short"
session_name="$(echo "$repo_short" | tr . _)"
window_name="pr"
local_branch="pr-$pr_number"

# Clone if not cloned
if [[ ! -d "$clone_path" ]]; then
  echo "Cloning $repo_full..."
  if git clone "git@github.com:$repo_full" "$clone_path"; then
    echo "Clone complete."
  else
    echo "Clone failed. Press enter to dismiss."
    read -r
    exit 1
  fi
fi

# Reuse repo session and dedicated PR window inside it.
if ! tmux has-session -t="$session_name" 2>/dev/null; then
  tmux new-session -ds "$session_name" -c "$clone_path"
fi

if tmux list-windows -t "$session_name" -F '#{window_name}' 2>/dev/null | grep -qx "$window_name"; then
  tmux select-window -t "$session_name:$window_name"
else
  tmux new-window -t "$session_name" -n "$window_name" -c "$clone_path"
fi

checkout_cmd="clear && printf 'Checking out PR #$pr_number into $local_branch\\n' && git fetch --quiet origin --prune && gh pr checkout \"$pr_number\" --repo \"$repo_full\" --force --branch \"$local_branch\" >/dev/null && printf 'Ready: %s (%s)\\n' \"$local_branch\" \"$repo_full\" && git status --short --branch"
tmux send-keys -t "$session_name:$window_name" "$checkout_cmd" C-m

if [[ "${TMUX-}" != '' ]]; then
  tmux switch-client -t "$session_name"
else
  tmux attach -t "$session_name"
fi
