#!/usr/bin/env bash

repo_full="${1:-}"
pr_number="${2:-}"
branch="${3:-}"

# Derive repo from git remote if not passed
if [[ -z "$repo_full" ]]; then
  remote=$(git remote get-url origin 2>/dev/null) || { echo "Not a git repo and no repo arg provided." >&2; exit 1; }
  repo_full=$(echo "$remote" | sed 's|.*github.com[:/]\(.*\)\.git|\1|' | sed 's|.*github.com[:/]\(.*\)|\1|')
fi

repo_short="${repo_full##*/}"
clone_path="$HOME/git/$repo_short"
worktree_path="$HOME/git/${repo_short}-pr-${pr_number}-wk"
window_name="pr-${repo_short}-${pr_number}"

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

# Fetch latest
git -C "$clone_path" fetch --quiet origin 2>/dev/null || true

# Create worktree
if [[ ! -d "$worktree_path" ]]; then
  echo "Creating worktree for PR #$pr_number ($branch)..."
  if git -C "$clone_path" show-ref --verify --quiet "refs/heads/$branch"; then
    git -C "$clone_path" worktree add "$worktree_path" "$branch"
  else
    git -C "$clone_path" worktree add "$worktree_path" -b "$branch" "origin/$branch"
  fi
fi

# Switch to existing window or create new one
if tmux list-windows -F '#{window_name}' 2>/dev/null | grep -qx "$window_name"; then
  tmux select-window -t "$window_name"
else
  tmux new-window -n "$window_name" -c "$worktree_path"
fi
