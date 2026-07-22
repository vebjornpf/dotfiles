#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$REPO_ROOT/config"

export PATH="$HOME/.local/bin:$PATH"

. "$REPO_ROOT/lib/platform.sh"

log() { printf '[bootstrap] %s\n' "$*"; }
warn() { printf '[bootstrap] warning: %s\n' "$*" >&2; }
die() { printf '[bootstrap] error: %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<'EOF'
Usage:
  ./bootstrap.sh core
  ./bootstrap.sh check core
  ./bootstrap.sh install core
  ./bootstrap.sh link core
  ./bootstrap.sh verify core
EOF
}

core_packages=(zsh tmux nvim)
core_commands=(git stow zsh tmux nvim fzf rg bat)
core_paths=(
  'oh-my-zsh|d|~/.oh-my-zsh'
  'catppuccin theme|t|catppuccin theme'
  'zsh-autosuggestions plugin|d|~/.oh-my-zsh/custom/plugins/zsh-autosuggestions'
  'zsh-syntax-highlighting plugin|d|~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting'
  'tmux TPM|d|~/.config/tmux/plugins/tpm'
  '~/.zshenv|e|~/.zshenv'
  '~/.config/zsh/.zshrc|e|~/.config/zsh/.zshrc'
  '~/.config/tmux/tmux.conf|e|~/.config/tmux/tmux.conf'
  '~/.config/nvim/init.lua|e|~/.config/nvim/init.lua'
)

expand_home() {
  printf '%s' "${1/#\~/$HOME}"
}

command_present() {
  command -v "$1" >/dev/null 2>&1 || [[ "$1" == 'bat' && $(command -v batcat 2>/dev/null || true) ]]
}

theme_present() {
  [[ -f "$HOME/.oh-my-zsh/themes/catppuccin.zsh-theme" ]] \
    || [[ -f "$HOME/.oh-my-zsh/custom/themes/catppuccin.zsh-theme" ]] \
    || [[ -f "$HOME/.oh-my-zsh/custom/themes/catppuccin/catppuccin.zsh-theme" ]]
}

path_present() {
  local kind=$1 value=$2
  case "$kind" in
    d) [[ -d "$(expand_home "$value")" ]] ;;
    e) [[ -e "$(expand_home "$value")" ]] ;;
    t) theme_present ;;
    *) return 1 ;;
  esac
}

detect_package_manager() {
  command -v brew >/dev/null 2>&1 && { printf 'brew'; return 0; }
  command -v apt-get >/dev/null 2>&1 && { printf 'apt'; return 0; }
  return 1
}

package_name_for() {
  case "$1" in
    nvim) printf 'neovim' ;;
    rg) printf 'ripgrep' ;;
    *) printf '%s' "$1" ;;
  esac
}

install_packages() {
  local manager=$1
  shift
  [[ $# -gt 0 ]] || { log 'All core packages already installed'; return 0; }

  log "Installing missing packages via $manager: $*"
  case "$manager" in
    brew) brew install "$@" ;;
    apt) sudo apt-get update && sudo apt-get install -y "$@" ;;
    *) die "Unsupported package manager: $manager" ;;
  esac
}

ensure_bat_wrapper() {
  command -v bat >/dev/null 2>&1 && return 0
  command -v batcat >/dev/null 2>&1 || return 0

  mkdir -p "$HOME/.local/bin"
  printf '#!/usr/bin/env sh\nexec batcat "$@"\n' >"$HOME/.local/bin/bat"
  chmod +x "$HOME/.local/bin/bat"
  log 'Installed ~/.local/bin/bat wrapper for batcat'
}

ensure_repo_clone() {
  local repo_url=$1 target_dir=$2
  [[ -d "$target_dir/.git" ]] && { log "Already present: $target_dir"; return 0; }
  mkdir -p "$(dirname "$target_dir")"
  log "Cloning $repo_url -> $target_dir"
  git clone --depth=1 "$repo_url" "$target_dir"
}

ensure_support_repos() {
  local entry repo target
  for entry in \
    'https://github.com/ohmyzsh/ohmyzsh.git|~/.oh-my-zsh' \
    'https://github.com/zsh-users/zsh-autosuggestions|~/.oh-my-zsh/custom/plugins/zsh-autosuggestions' \
    'https://github.com/zsh-users/zsh-syntax-highlighting.git|~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting' \
    'https://github.com/tmux-plugins/tpm|~/.config/tmux/plugins/tpm'
  do
    repo=${entry%%|*}
    target=$(expand_home "${entry#*|}")
    ensure_repo_clone "$repo" "$target"
  done
}

current_login_shell() {
  if command -v getent >/dev/null 2>&1; then
    getent passwd "$USER" | cut -d: -f7 2>/dev/null || true
  elif command -v dscl >/dev/null 2>&1; then
    dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk '{print $2}' || true
  fi
}

ensure_default_shell() {
  local zsh_path shell_path
  zsh_path=$(command -v zsh)
  shell_path=$(current_login_shell)

  [[ -n "$shell_path" && "$shell_path" == "$zsh_path" ]] && {
    log "Default shell already set to $zsh_path"
    return 0
  }
  [[ "${SHELL:-}" == "$zsh_path" ]] && log "Current shell already uses $zsh_path; login shell may still need updating"
  command -v chsh >/dev/null 2>&1 || { warn "chsh not found. Set your login shell manually to: $zsh_path"; return 0; }

  log "Setting default shell to $zsh_path"
  chsh -s "$zsh_path" && { log 'Default shell updated'; return 0; }
  warn "Could not update default shell automatically. Run: chsh -s $zsh_path"
}

report_commands() {
  local strict=${1:-0} cmd failed=0
  for cmd in "${core_commands[@]}"; do
    if command_present "$cmd"; then
      log "OK command: $cmd"
    else
      warn "Missing command: $cmd"
      failed=1
    fi
  done
  [[ $strict -eq 0 || $failed -eq 0 ]]
}

report_paths() {
  local strict=${1:-0} entry label kind value failed=0
  for entry in "${core_paths[@]}"; do
    IFS='|' read -r label kind value <<<"$entry"
    if path_present "$kind" "$value"; then
      log "OK $label"
    else
      warn "Missing $label"
      failed=1
    fi
  done
  [[ $strict -eq 0 || $failed -eq 0 ]]
}

check_core() {
  local manager pkg

  log "Platform: $(detect_platform)"
  manager=$(detect_package_manager 2>/dev/null || true)
  [[ -n "$manager" ]] && log "Package manager: $manager" || warn 'No supported package manager detected automatically (supported: brew, apt-get)'

  report_commands
  report_paths

  for pkg in "${core_packages[@]}"; do
    if [[ "$pkg" == 'zsh' ]]; then
      [[ -e "$HOME/.zshenv" ]] && log 'Linked package looks present: zsh' || warn 'Package not linked yet: zsh'
    elif [[ -e "$HOME/.config/$pkg" ]]; then
      log "Linked package looks present: $pkg"
    else
      warn "Package not linked yet: $pkg"
    fi
  done

  log "EDITOR=${EDITOR:-<unset>}"
  log "VISUAL=${VISUAL:-<unset>}"
  log "SHELL=${SHELL:-<unset>}"
  warn 'Manual checks still required: Nerd Font configured in terminal, open tmux and press prefix + I after first link'
}

install_core() {
  local manager cmd
  local missing_packages=()

  manager=$(detect_package_manager 2>/dev/null) || die 'No supported package manager detected automatically. Install core dependencies manually first.'
  for cmd in "${core_commands[@]}"; do
    command_present "$cmd" || missing_packages+=("$(package_name_for "$cmd")")
  done

  install_packages "$manager" "${missing_packages[@]}"
  ensure_bat_wrapper
  ensure_support_repos
  ensure_default_shell
}

link_core() {
  command -v stow >/dev/null 2>&1 || die 'stow is required before linking core packages'

  local pkg
  for pkg in "${core_packages[@]}"; do
    [[ -d "$CONFIG_DIR/$pkg" ]] || { warn "Skipping missing package directory: $pkg"; continue; }
    log "Stowing $pkg"
    (cd "$CONFIG_DIR" && stow --restow -t "$HOME" "$pkg")
  done
}

verify_core() {
  report_commands 1 && report_paths 1 || die 'Core bootstrap verification failed'
  log 'Core bootstrap verification passed'
  warn 'Still do these manually: start a new login shell, open tmux and press prefix + I, configure a Nerd Font in your terminal'
}

require_core_target() {
  local command=$1 target=${2:-}
  [[ "$target" == 'core' ]] || die "Usage: ./bootstrap.sh $command core"
}

main() {
  case "${1:-}" in
    core) install_core; link_core; verify_core ;;
    check) require_core_target check "${2:-}"; check_core ;;
    install) require_core_target install "${2:-}"; install_core ;;
    link) require_core_target link "${2:-}"; link_core ;;
    verify) require_core_target verify "${2:-}"; verify_core ;;
    -h|--help|help|'') usage ;;
    *) die "Unknown command: ${1:-}" ;;
  esac
}

main "$@"
