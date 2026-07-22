#!/usr/bin/env bash

set -euo pipefail

lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$lib_dir/env.sh"

state_dir="${GHREPO_STATE_DIR:-$HOME/git/daily/ghrepo}"
repos_file="$state_dir/repos.tsv"

require_ghrepo_org
mkdir -p "$state_dir"

tmpfile="$(mktemp)"
trap 'rm -f "${tmpfile:-}"' EXIT

gh repo list "$GHREPO_ORG" --limit 1000 --json nameWithOwner,url,isArchived \
  | jq -r '.[] | select(.isArchived | not) | [.nameWithOwner, .url] | @tsv' >"$tmpfile"

mv "$tmpfile" "$repos_file"
printf 'Synced repos: %s\n' "$(wc -l < "$repos_file")"
