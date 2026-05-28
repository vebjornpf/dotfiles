#!/usr/bin/env bash

repo_full="${1:-}"

if [[ -z "$repo_full" ]]; then
  echo "Usage: assignedprs-open.sh <org/repo>" >&2
  exit 1
fi

repo_short="${repo_full##*/}"
session_name=$(echo "$repo_short" | tr . _)
clone_path="$HOME/git/$repo_short"

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

if ! tmux has-session -t="$session_name" 2>/dev/null; then
  tmux new-session -ds "$session_name" -c "$clone_path"
fi

if [[ "${TMUX-}" != '' ]]; then
  tmux switch-client -t "$session_name"
else
  tmux attach -t "$session_name"
fi
