export GHPR_HOME="$HOME/.config/ghpr"
export GHPR_STATE_DIR="$HOME/git/daily/ghpr"

# Optional local overrides live outside stow-managed config.
[[ -f "$HOME/.config/local/tools.zsh" ]] && source "$HOME/.config/local/tools.zsh"

local ghpr_bin_dir="$GHPR_HOME/bin"

if [[ -d "$ghpr_bin_dir" && ":$PATH:" != *":$ghpr_bin_dir:"* ]]; then
  path=("$ghpr_bin_dir" $path)
fi

_ghpr() {
  local -a top_level sync_targets mine_commands

  top_level=(this mine open sync)
  sync_targets=(mine)
  mine_commands=(clean list status)

  if (( CURRENT == 2 )); then
    compadd -- "${top_level[@]}"
    return
  fi

  case "${words[2]-}" in
    sync)
      if (( CURRENT == 3 )); then
        compadd -- "${sync_targets[@]}"
      fi
      ;;
    mine)
      if (( CURRENT == 3 )); then
        compadd -- "${mine_commands[@]}"
      fi
      ;;
  esac
}

compdef _ghpr ghpr
