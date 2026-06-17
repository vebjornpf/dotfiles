#!/usr/bin/env bash

GHPR_HOME="${GHPR_HOME:-$HOME/.config/ghpr}"
GHPR_STATE_DIR="${GHPR_STATE_DIR:-$HOME/git/daily/ghpr}"

mine_state_file() {
  printf '%s/mine.json\n' "$GHPR_STATE_DIR"
}

ensure_ghpr_state_dir() {
  mkdir -p "$GHPR_STATE_DIR"
}

ensure_mine_cache() {
  local state_file

  state_file="$(mine_state_file)"
  if [[ ! -f "$state_file" ]]; then
    "$GHPR_HOME/bin/ghpr-sync" mine >/dev/null
  fi
}
