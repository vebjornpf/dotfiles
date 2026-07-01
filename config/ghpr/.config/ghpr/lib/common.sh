#!/usr/bin/env bash

GHPR_HOME="${GHPR_HOME:-$HOME/.config/ghpr}"
GHPR_STATE_DIR="${GHPR_STATE_DIR:-$HOME/git/daily/ghpr}"

repo_short_name() {
  local repo_full="${1:-}"
  printf '%s\n' "${repo_full##*/}"
}

repo_clone_path() {
  local repo_full="${1:-}"
  printf '%s/git/%s\n' "$HOME" "$(repo_short_name "$repo_full")"
}

ensure_repo_clone() {
  local repo_full="${1:-}"
  local clone_path

  clone_path="$(repo_clone_path "$repo_full")"
  if [[ -d "$clone_path" ]]; then
    return 0
  fi

  echo "Cloning $repo_full..."
  if git clone "git@github.com:$repo_full" "$clone_path"; then
    echo "Clone complete."
    return 0
  fi

  echo "Clone failed. Press enter to dismiss."
  read -r
  return 1
}

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
