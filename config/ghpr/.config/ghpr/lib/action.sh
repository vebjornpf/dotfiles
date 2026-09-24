#!/usr/bin/env bash

set -euo pipefail

GHPR_HOME="${GHPR_HOME:-$HOME/.config/ghpr}"
action="${1:-}"
repo="${2:-}"
number="${3:-}"

if [[ -z "$action" || -z "$repo" || -z "$number" ]]; then
  echo "Usage: action.sh <action> <repo> <number>" >&2
  exit 1
fi

pause() {
  printf '\nPress enter to return to ghpr. '
  read -r
}

show_failure() {
  local status=$?
  trap - ERR
  printf '\nAction failed with exit code %s.\n' "$status" >&2
  pause
  exit "$status"
}

trap show_failure ERR

edit_body() {
  local prompt="${1:-Write a message}"
  local body tmpfile
  tmpfile="$(mktemp)"
  printf '# %s\n# Lines beginning with # are ignored.\n' "$prompt" >"$tmpfile"
  "${VISUAL:-${EDITOR:-vi}}" "$tmpfile" </dev/tty >/dev/tty
  body="$(sed '/^#/d' "$tmpfile")"
  rm -f "$tmpfile"
  printf '%s' "$body"
}

case "$action" in
  open)
    trap - ERR
    gh pr view "$number" --repo "$repo" --web
    ;;
  copy)
    trap - ERR
    # shellcheck source=/dev/null
    source "$HOME/.config/zsh/lib/clipboard.sh"
    gh pr view "$number" --repo "$repo" --json url -q .url | clipboard_copy
    ;;
  comment)
    body="$(edit_body "Comment on $repo#$number")"
    if [[ -n "${body//[[:space:]]/}" ]]; then
      gh pr comment "$number" --repo "$repo" --body "$body"
    else
      echo "Comment cancelled."
    fi
    pause
    ;;
  approve)
    gh pr review "$number" --repo "$repo" --approve
    pause
    ;;
  request-changes)
    body="$(edit_body "Request changes on $repo#$number")"
    if [[ -n "${body//[[:space:]]/}" ]]; then
      gh pr review "$number" --repo "$repo" --request-changes --body "$body"
    else
      echo "Review cancelled."
    fi
    pause
    ;;
  merge)
    printf 'Squash merge %s#%s? [y/N] ' "$repo" "$number"
    read -r answer
    if [[ "$answer" == y || "$answer" == Y ]]; then
      gh pr merge "$number" --repo "$repo" --squash
    else
      echo "Merge cancelled."
    fi
    pause
    ;;
  toggle-draft)
    draft="$(gh pr view "$number" --repo "$repo" --json isDraft -q .isDraft)"
    if [[ "$draft" == true ]]; then
      gh pr ready "$number" --repo "$repo"
    else
      gh pr ready "$number" --repo "$repo" --undo
    fi
    pause
    ;;
  update-branch)
    gh pr update-branch "$number" --repo "$repo"
    pause
    ;;
  checks)
    gh pr checks "$number" --repo "$repo"
    pause
    ;;
  *)
    echo "Unknown action: $action" >&2
    exit 1
    ;;
esac
