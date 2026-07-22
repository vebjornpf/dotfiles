#!/usr/bin/env bash

set -euo pipefail

lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$lib_dir/common.sh"

require_repos_file

declare -A local_repos=()

while IFS=$'\t' read -r normalized_url repo_dir; do
  local_repos["$normalized_url"]="$repo_dir"
done < <(scan_local_repos)

while IFS=$'\t' read -r slug url; do
  normalized_url="$(normalize_git_url "$url")"
  repo_dir="${local_repos[$normalized_url]:-}"

  if [[ -n "$repo_dir" ]]; then
    display="\033[32m$slug\033[0m"
  else
    display="\033[31m$slug\033[0m"
  fi

  printf '%b\t%s\t%s\t%s\n' "$display" "$slug" "$url" "$repo_dir"
done < "$(ghrepo_repos_file)"
