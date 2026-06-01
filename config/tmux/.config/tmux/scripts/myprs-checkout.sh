#!/usr/bin/env bash

# Usage: myprs-checkout.sh <org/repo> <pr_number>
repo_full="${1:-}"
pr_number="${2:-}"

if [[ -z "$repo_full" || -z "$pr_number" ]]; then
  echo "Usage: myprs-checkout.sh <org/repo> <pr_number>" >&2
  exit 1
fi

repo_short="${repo_full##*/}"
clone_path="$HOME/git/$repo_short"

if [[ ! -d "$clone_path" ]]; then
  tmux display-popup -E "git clone git@github.com:$repo_full $clone_path && echo '' && echo 'Clone complete. Press enter to continue.' && read || (echo '' && echo 'Clone failed. Press enter to dismiss.' && read)"
fi

cd "$clone_path"
gh pr checkout "$pr_number" --repo "$repo_full"
