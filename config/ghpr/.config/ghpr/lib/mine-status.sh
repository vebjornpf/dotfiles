#!/usr/bin/env bash

set -euo pipefail

GHPR_HOME="${GHPR_HOME:-$HOME/.config/ghpr}"
source "$GHPR_HOME/lib/common.sh"

ensure_mine_cache

count="$(jq '.prs | length' "$(mine_state_file)")"
printf 'mine:%s\n' "$count"
