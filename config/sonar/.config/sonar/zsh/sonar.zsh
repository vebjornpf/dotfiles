export SONAR_HOME="$HOME/.config/sonar"

# Optional local overrides live outside stow-managed config.
# Supported variables:
#   SONAR_BASE_URL
#   SONAR_TOKEN
[[ -f "$HOME/.config/local/tools.zsh" ]] && source "$HOME/.config/local/tools.zsh"

local sonar_bin_dir="$SONAR_HOME/bin"

if [[ -d "$sonar_bin_dir" && ":$PATH:" != *":$sonar_bin_dir:"* ]]; then
  path=("$sonar_bin_dir" $path)
fi

_sonar() {
  local -a commands qualities

  commands=(sync rules export status path pr web)
  qualities=(maintainability security reliability all)

  if (( CURRENT == 2 )); then
    compadd -- "${commands[@]}"
    return
  fi

  case "${words[2]-}" in
    sync|rules|export|status|path)
      compadd -- "${qualities[@]}"
      ;;
  esac
}

compdef _sonar sonar
