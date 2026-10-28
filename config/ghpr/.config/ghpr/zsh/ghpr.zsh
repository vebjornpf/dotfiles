export GHPR_HOME="$HOME/.config/ghpr"
export GHPR_STATE_DIR="$HOME/git/daily/ghpr"

# Optional local overrides live outside stow-managed config.
[[ -f "$HOME/.config/local/tools.zsh" ]] && source "$HOME/.config/local/tools.zsh"

local ghpr_bin_dir="$GHPR_HOME/bin"

if [[ -d "$ghpr_bin_dir" && ":$PATH:" != *":$ghpr_bin_dir:"* ]]; then
  path=("$ghpr_bin_dir" $path)
fi

# Wrap display text without changing the value inserted by completion.
_ghpr_completion_wrap() {
  local text="${1//[[:cntrl:]]/ }" word char line="${3-}" indent='     '
  local -i width=$2
  (( width > ${#indent} )) || indent=''
  REPLY=''

  for word in ${=text}; do
    if [[ -n "${line// /}" ]]; then
      if (( ${(m)#line} + 1 + ${(m)#word} <= width )); then
        line+=" $word"
        continue
      fi
      REPLY+="$line"$'\n'
      line="$indent"
    fi

    # Also break long unspaced values, such as branch names.
    for char in ${(s::)word}; do
      if (( ${(m)#line} + ${(m)#char} > width )); then
        REPLY+="$line"$'\n'
        line="$indent"
      fi
      line+="$char"
    done
  done
  REPLY+="$line"
}

_ghpr() {
  local -a top_level sync_targets mine_commands this_commands

  top_level=(this mine open sync)
  sync_targets=(mine)
  mine_commands=(clean list status)
  this_commands=(open checkout cp)

  if (( CURRENT == 2 )); then
    compadd -- "${top_level[@]}"
    return
  fi

  case "${words[2]-}" in
    this)
      if (( CURRENT == 4 )) && [[ "${words[3]-}" == <-> ]]; then
        compadd -- "${this_commands[@]}"
      elif (( CURRENT == 3 )) || { (( CURRENT == 4 )) && [[ "${words[3]-}" == open || "${words[3]-}" == checkout || "${words[3]-}" == cp ]]; }; then
        local number repo author updated state title url branch display field REPLY
        local -i width=$(( COLUMNS > 1 ? COLUMNS - 1 : 1 ))
        local -a prs displays

        while IFS=$'\t' read -r number repo author updated state title url branch; do
          prs+=("$number")
          _ghpr_completion_wrap "$title" "$width" "$number "
          display="$REPLY"
          for field in "Author: $author" "State: $state" "Branch: $branch" "Updated: ${updated%%T*}"; do
            _ghpr_completion_wrap "$field" "$width" '     '
            display+=$'\n'"$REPLY"
          done
          displays+=("$display"$'\n')
        done < <(bash "$GHPR_HOME/lib/query.sh" this-completions 2>/dev/null)

        # One multiline display per match; preserve the query's update ordering.
        compadd -l -V ghpr-pull-requests -d displays -- "${prs[@]}"
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
