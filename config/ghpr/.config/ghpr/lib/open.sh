#!/usr/bin/env bash

set -euo pipefail

GHPR_HOME="${GHPR_HOME:-$HOME/.config/ghpr}"
source "$GHPR_HOME/lib/common.sh"

repo_full="${1:-}"
pr_number="${2:-}"
branch_name="${3:-}"

if [[ -z "$pr_number" ]]; then
  echo "Usage: ghpr open <org/repo> <pr_number> [branch]" >&2
  exit 1
fi

if [[ -z "$repo_full" ]]; then
  remote=$(git remote get-url origin 2>/dev/null) || { echo "Not a git repo and no repo arg provided." >&2; exit 1; }
  repo_full=$(echo "$remote" | sed 's|.*github.com[:/]\(.*\)\.git|\1|' | sed 's|.*github.com[:/]\(.*\)|\1|')
fi

clone_path="$(repo_clone_path "$repo_full")"

case "$branch_name" in
  ""|null|not_available)
    local_branch="pr-$pr_number"
    ;;
  *)
    local_branch="$branch_name"
    ;;
esac

ensure_repo_clone "$repo_full"

cd "$clone_path"
printf 'Checking out PR #%s into %s\n' "$pr_number" "$local_branch"
git fetch --quiet origin --prune
gh pr checkout "$pr_number" --repo "$repo_full" --force --branch "$local_branch" >/dev/null
printf 'Ready: %s (%s)\n' "$local_branch" "$repo_full"
git status --short --branch
printf '\n'
exec "${SHELL:-bash}" -i
