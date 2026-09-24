#!/usr/bin/env bash

set -euo pipefail

GHPR_HOME="${GHPR_HOME:-$HOME/.config/ghpr}"
repo="${1:-}"
number="${2:-}"
session="${3:-}"

if [[ ! "$repo" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ || ! "$number" =~ ^[0-9]+$ || -z "$session" ]]; then
  echo 'Usage: fetch-detail.sh <owner/repo> <number> <session>' >&2
  exit 1
fi

destination="$session/details/$repo/$number.json"
[[ -f "$destination" ]] && exit 0

mkdir -p "$(dirname "$destination")"
tmpfile="$(mktemp "$session/.detail.XXXXXXXX")"
trap 'rm -f "$tmpfile"' EXIT

bash "$GHPR_HOME/lib/detail.sh" "$repo" "$number" >"$tmpfile"
mv "$tmpfile" "$destination"
