#!/usr/bin/env bash

set -euo pipefail

GHPR_HOME="${GHPR_HOME:-$HOME/.config/ghpr}"
source "$GHPR_HOME/lib/common.sh"

repo="${1:-}"
number="${2:-}"

if [[ -z "$repo" || -z "$number" ]]; then
  echo "Usage: mine-item.sh <repo> <number>" >&2
  exit 1
fi

ensure_mine_cache

jq --arg repo "$repo" --arg number "$number" -e '
  .prs[]
  | select(.repo == $repo and .number == $number)
' "$(mine_state_file)"
