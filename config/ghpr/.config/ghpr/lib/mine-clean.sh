#!/usr/bin/env bash

set -euo pipefail

GHPR_HOME="${GHPR_HOME:-$HOME/.config/ghpr}"
source "$GHPR_HOME/lib/common.sh"

state_file="$(mine_state_file)"

if [[ -f "$state_file" ]]; then
  rm "$state_file"
fi
