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
  ./bootstrap.sh tools
  ./bootstrap.sh check core
  ./bootstrap.sh check tools
  ./bootstrap.sh install core
  ./bootstrap.sh install tools
  ./bootstrap.sh link core
  ./bootstrap.sh link tools
  ./bootstrap.sh verify core
  ./bootstrap.sh verify tools
EOF
}

core_packages=(zsh tmux nvim)
core_commands=(git stow zsh tmux nvim fzf rg bat)
tools_packages=(jira ghpr ghrepo sonar web opencode)
tools_commands=(gh jq curl acli node npm)
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
tools_paths=(
  '~/.config/local/tools.zsh|e|~/.config/local/tools.zsh'
  '~/.config/jira|e|~/.config/jira'
  '~/.config/ghpr|e|~/.config/ghpr'
  '~/.config/ghrepo|e|~/.config/ghrepo'
  '~/.config/sonar|e|~/.config/sonar'
  '~/.config/web|e|~/.config/web'
  '~/.config/opencode/package.json|e|~/.config/opencode/package.json'
  'opencode plugin install|d|~/.config/opencode/node_modules/@opencode-ai/plugin'
)
tools_required_vars=(GHREPO_ORG JIRA_PROJECT_KEY JIRA_BASE_URL JIRA_BOARD_URL SONAR_BASE_URL SONAR_TOKEN)

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

shell_listed() {
  local shell_path=$1 line
  [[ -n "$shell_path" && -r /etc/shells ]] || return 1

  while IFS= read -r line; do
    [[ "$line" == "$shell_path" ]] && return 0
  done </etc/shells

  return 1
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
  local manager=${1:-} command=${2:-}
  case "$manager:$command" in
    brew:node|brew:npm) printf 'node' ;;
    apt:node) printf 'nodejs' ;;
    apt:npm) printf 'npm' ;;
    *:nvim) printf 'neovim' ;;
    *:rg) printf 'ripgrep' ;;
    *:gh) printf 'gh' ;;
    *:jq) printf 'jq' ;;
    *:curl) printf 'curl' ;;
    *:acli) printf 'acli' ;;
    *) printf '%s' "$command" ;;
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

resolve_login_zsh() {
  local candidate current shell_path
  candidate=$(command -v zsh 2>/dev/null || true)
  current=$(current_login_shell)

  for shell_path in "$current" "$candidate" /usr/bin/zsh /bin/zsh; do
    [[ -n "$shell_path" ]] || continue
    [[ "${shell_path##*/}" == 'zsh' ]] || continue
    [[ -x "$shell_path" ]] || continue
    shell_listed "$shell_path" && {
      printf '%s' "$shell_path"
      return 0
    }
  done

  printf '%s' "$candidate"
}

ensure_default_shell() {
  local zsh_path shell_path discovered_zsh
  discovered_zsh=$(command -v zsh 2>/dev/null || true)
  zsh_path=$(resolve_login_zsh)
  shell_path=$(current_login_shell)

  [[ -n "$zsh_path" ]] || { warn 'zsh not found. Set your login shell manually after installing zsh'; return 0; }

  [[ -n "$shell_path" && "$shell_path" == "$zsh_path" ]] && {
    log "Default shell already set to $zsh_path"
    return 0
  }
  [[ "${SHELL:-}" == "$zsh_path" ]] && log "Current shell already uses $zsh_path; login shell may still need updating"
  command -v chsh >/dev/null 2>&1 || { warn "chsh not found. Set your login shell manually to: $zsh_path"; return 0; }

  if [[ "$zsh_path" != "$discovered_zsh" && -n "$discovered_zsh" ]]; then
    warn "Using $zsh_path for login shell because $discovered_zsh is not listed in /etc/shells"
  elif ! shell_listed "$zsh_path"; then
    warn "Could not find a zsh path listed in /etc/shells. Add $zsh_path to /etc/shells, then run: chsh -s $zsh_path"
    return 0
  fi

  log "Setting default shell to $zsh_path"
  chsh -s "$zsh_path" && { log 'Default shell updated'; return 0; }
  warn "Could not update default shell automatically. Run: chsh -s $zsh_path"
}

report_commands() {
  local strict=${1:-0}
  shift
  local cmd failed=0
  for cmd in "$@"; do
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
  local strict=${1:-0}
  shift
  local entry label kind value failed=0
  for entry in "$@"; do
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

  report_commands 0 "${core_commands[@]}"
  report_paths 0 "${core_paths[@]}"

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
    command_present "$cmd" || missing_packages+=("$(package_name_for "$manager" "$cmd")")
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
  report_commands 1 "${core_commands[@]}" && report_paths 1 "${core_paths[@]}" || die 'Core bootstrap verification failed'
  log 'Core bootstrap verification passed'
  warn 'Still do these manually: start a new login shell, open tmux and press prefix + I, configure a Nerd Font in your terminal'
}

report_required_vars() {
  local strict=${1:-0}
  shift
  local name failed=0
  for name in "$@"; do
    if [[ -n "${!name:-}" ]]; then
      log "OK variable: $name"
    else
      warn "Missing variable: $name"
      failed=1
    fi
  done
  [[ $strict -eq 0 || $failed -eq 0 ]]
}

install_opencode_deps() {
  [[ -f "$HOME/.config/opencode/package.json" ]] || return 0
  log 'Installing opencode npm dependencies'
  (cd "$HOME/.config/opencode" && npm install)
}

link_packages() {
  command -v stow >/dev/null 2>&1 || die 'stow is required before linking packages'
  local pkg
  for pkg in "$@"; do
    [[ -d "$CONFIG_DIR/$pkg" ]] || { warn "Skipping missing package directory: $pkg"; continue; }
    log "Stowing $pkg"
    (cd "$CONFIG_DIR" && stow --restow -t "$HOME" "$pkg")
  done
}

check_tools() {
  local manager pkg
  log "Platform: $(detect_platform)"
  manager=$(detect_package_manager 2>/dev/null || true)
  [[ -n "$manager" ]] && log "Package manager: $manager" || warn 'No supported package manager detected automatically (supported: brew, apt-get)'

  report_commands 0 "${tools_commands[@]}"
  report_paths 0 "${tools_paths[@]}"

  if [[ -f "$HOME/.config/local/tools.zsh" ]]; then
    # shellcheck disable=SC1090
    source "$HOME/.config/local/tools.zsh"
  fi
  report_required_vars 0 "${tools_required_vars[@]}"

  for pkg in "${tools_packages[@]}"; do
    [[ -e "$HOME/.config/$pkg" ]] && log "Linked package looks present: $pkg" || warn "Package not linked yet: $pkg"
  done
  warn 'Manual checks still required: run `gh auth status`, make sure `acli` is authenticated, and confirm repo-level Sonar `.sonar/project` files where needed'
}

install_tools() {
  local manager cmd package
  local missing_packages=()

  manager=$(detect_package_manager 2>/dev/null) || die 'No supported package manager detected automatically. Install tool dependencies manually first.'
  for cmd in "${tools_commands[@]}"; do
    if command_present "$cmd"; then
      continue
    fi
    package=$(package_name_for "$manager" "$cmd")
    [[ "$package" == 'acli' && "$manager" == 'apt' ]] && die 'Install `acli` manually before running tool bootstrap on apt-based systems.'
    missing_packages+=("$package")
  done

  if [[ ${#missing_packages[@]} -gt 0 ]]; then
    # de-duplicate while preserving order
    local deduped=() seen=" "
    local item
    for item in "${missing_packages[@]}"; do
      [[ "$seen" == *" $item "* ]] && continue
      deduped+=("$item")
      seen+="$item "
    done
    install_packages "$manager" "${deduped[@]}"
  else
    log 'All tool packages already installed'
  fi
}

link_tools() {
  link_packages "${tools_packages[@]}"
}

verify_tools() {
  if [[ -f "$HOME/.config/local/tools.zsh" ]]; then
    # shellcheck disable=SC1090
    source "$HOME/.config/local/tools.zsh"
  fi

  report_commands 1 "${tools_commands[@]}" \
    && report_paths 1 "${tools_paths[@]}" \
    && report_required_vars 1 "${tools_required_vars[@]}" \
    || die 'Tools bootstrap verification failed'

  log 'Tools bootstrap verification passed'
  warn 'Still do these manually: run `gh auth status`, make sure `acli` is authenticated, and confirm repo-level Sonar `.sonar/project` files where needed'
}

run_tools() {
  install_tools
  link_tools
  install_opencode_deps
  verify_tools
}

require_target() {
  local command=$1 target=${2:-}
  local expected=$3
  [[ "$target" == "$expected" ]] || die "Usage: ./bootstrap.sh $command $expected"
}

main() {
  case "${1:-}" in
    core) install_core; link_core; verify_core ;;
    tools) run_tools ;;
    check)
      case "${2:-}" in
        core) check_core ;;
        tools) check_tools ;;
        *) die 'Usage: ./bootstrap.sh check core|tools' ;;
      esac
      ;;
    install)
      case "${2:-}" in
        core) install_core ;;
        tools) install_tools ;;
        *) die 'Usage: ./bootstrap.sh install core|tools' ;;
      esac
      ;;
    link)
      case "${2:-}" in
        core) link_core ;;
        tools) link_tools ;;
        *) die 'Usage: ./bootstrap.sh link core|tools' ;;
      esac
      ;;
    verify)
      case "${2:-}" in
        core) verify_core ;;
        tools) verify_tools ;;
        *) die 'Usage: ./bootstrap.sh verify core|tools' ;;
      esac
      ;;
    -h|--help|help|'') usage ;;
    *) die "Unknown command: ${1:-}" ;;
  esac
}

main "$@"
