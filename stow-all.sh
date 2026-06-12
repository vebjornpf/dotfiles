#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$REPO_ROOT/config"

. "$REPO_ROOT/lib/platform.sh"

log() { printf '[stow-all] %s\n' "$*"; }

if ! command -v stow >/dev/null 2>&1; then
  log "stow not found — install it first (brew install stow / apt install stow)"
  exit 1
fi

cd "$CONFIG_DIR" || exit 1

# Common packages — stowed on every platform
packages=(
  jira
  zsh
  nvim
  tmux
  opencode
)

# Platform-specific packages
case "$(detect_platform)" in
  macos)
    # packages+=(karabiner yabai)  # add macOS-only tools here when needed
    ;;
  linux)
    if is_wsl; then
      log "WSL detected"
    fi
    ;;
esac

for pkg in "${packages[@]}"; do
  if [ ! -d "$CONFIG_DIR/$pkg" ]; then
    log "Skipping $pkg (directory not found)"
    continue
  fi
  log "Stowing $pkg"
  stow --restow -t "$HOME" "$pkg"
done

log "Done. Run 'stow -D <pkg>' from config/ to unstow a package."
