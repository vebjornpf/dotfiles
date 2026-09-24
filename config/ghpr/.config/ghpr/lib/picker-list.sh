#!/usr/bin/env bash

set -euo pipefail

GHPR_HOME="${GHPR_HOME:-$HOME/.config/ghpr}"
target="${1:-mine}"
username="${2:-}"

bash "$GHPR_HOME/lib/query.sh" "$target" "$username" |
  while IFS=$'\t' read -r number repo author updated state title url; do
    repo_name="${repo#*/}"
    marker=""
    if [[ "$state" == draft ]]; then
      marker="[draft] "
    fi

    case "$target" in
      mine|user)
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t#%-5s %-24.24s %s%s\n' \
          "$number" "$repo" "$author" "$updated" "$state" "$title" "$url" \
          "$number" "$repo_name" "$marker" "$title"
        ;;
      this)
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t#%-5s %-16.16s %s%s\n' \
          "$number" "$repo" "$author" "$updated" "$state" "$title" "$url" \
          "$number" "$author" "$marker" "$title"
        ;;
      team)
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t#%-5s %-24.24s %-16.16s %s%s\n' \
          "$number" "$repo" "$author" "$updated" "$state" "$title" "$url" \
          "$number" "$repo_name" "$author" "$marker" "$title"
        ;;
      *)
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t#%-5s %-24.24s %s%s\n' \
          "$number" "$repo" "$author" "$updated" "$state" "$title" "$url" \
          "$number" "$repo_name" "$marker" "$title"
        ;;
    esac
  done
