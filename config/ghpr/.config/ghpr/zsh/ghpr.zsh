export GHPR_HOME="$HOME/.config/ghpr"
export GHPR_STATE_DIR="$HOME/git/daily/ghpr"

# Optional local overrides live outside stow-managed config.
[[ -f "$HOME/.config/local/tools.zsh" ]] && source "$HOME/.config/local/tools.zsh"

local ghpr_bin_dir="$GHPR_HOME/bin"

if [[ -d "$ghpr_bin_dir" && ":$PATH:" != *":$ghpr_bin_dir:"* ]]; then
  path=("$ghpr_bin_dir" $path)
fi

_ghpr() {
  local -a top_level sync_targets mine_commands this_commands

  top_level=(this mine open sync)
  sync_targets=(mine)
  mine_commands=(clean list status)
  this_commands=(open checkout)

  if (( CURRENT == 2 )); then
    compadd -- "${top_level[@]}"
    return
  fi

  case "${words[2]-}" in
    this)
      if (( CURRENT == 3 )); then
        compadd -- "${this_commands[@]}"
      elif (( CURRENT == 4 )) && [[ "${words[3]-}" == open || "${words[3]-}" == checkout ]]; then
        local number repo author updated state title url
        local -a prs

        while IFS=$'\t' read -r number repo author updated state title url; do
          prs+=("${number}:${title}")
        done < <(bash "$GHPR_HOME/lib/query.sh" this 2>/dev/null)

        _describe 'pull request' prs
      fi
      ;;
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
