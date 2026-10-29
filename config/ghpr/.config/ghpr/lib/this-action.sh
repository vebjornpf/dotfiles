#!/usr/bin/env bash

set -euo pipefail

GHPR_HOME="${GHPR_HOME:-$HOME/.config/ghpr}"

usage() {
  cat <<'EOF'
Usage: ghpr this [list | open | <number> <open|checkout|cp>]

With no arguments, open the current repository's PR picker.
`list` prints open PR numbers, authors, and titles in the current repository.
`open` opens the current repository's PR page in the browser.
Tab after `ghpr this ` fetches open PRs; select a PR, then Tab to choose:
  open      open the PR in the browser
  checkout  locally check out the PR
  cp        copy the PR URL

The action-first form `ghpr this <open|checkout|cp> <number>` also works.
EOF
}

if [[ "${1:-}" == -h || "${1:-}" == --help || "${1:-}" == help ]]; then
  usage
  exit 0
fi

if (( $# == 1 )) && [[ "$1" == open ]]; then
  gh pr list --web
  exit 0
fi

if (( $# == 1 )) && [[ "$1" == list ]]; then
  bash "$GHPR_HOME/lib/query.sh" this | {
    printf '%-8s %-20s %s\n' 'NUMBER' 'AUTHOR' 'TITLE'
    while IFS=$'\t' read -r number repo author updated state title url; do
      printf '%-8s %-20s %s\n' "#$number" "$author" "$title"
    done
  }
  exit 0
fi

if (( $# != 2 )); then
  usage >&2
  exit 1
fi

number="$1"
action="$2"
case "$1" in
  open|checkout|cp)
    action="$1"
    number="$2"
    ;;
esac

if [[ ! "$number" =~ ^[0-9]+$ ]]; then
  printf 'Invalid PR number: %s\n' "$number" >&2
  exit 1
fi

case "$action" in
  open)
    gh pr view "$number" --web
    ;;
  checkout)
    exec bash "$GHPR_HOME/lib/open.sh" "" "$number"
    ;;
  cp)
    source "$HOME/.config/zsh/lib/clipboard.sh"
    gh pr view "$number" --json url -q .url | clipboard_copy
    ;;
  *)
    printf 'Unknown ghpr this action: %s\n' "$action" >&2
    usage >&2
    exit 1
    ;;
esac
