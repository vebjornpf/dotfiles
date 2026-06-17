#!/usr/bin/env bash

set -euo pipefail

GHPR_HOME="${GHPR_HOME:-$HOME/.config/ghpr}"
source "$GHPR_HOME/lib/common.sh"

ensure_mine_cache

jq -r '.prs[] | "\(.number)\t\(.repo)\t\(.title)"' "$(mine_state_file)"
