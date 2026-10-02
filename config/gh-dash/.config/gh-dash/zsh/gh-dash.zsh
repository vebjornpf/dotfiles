export GH_DASH_HOME="${GH_DASH_HOME:-$HOME/.config/gh-dash}"
export GH_DASH_STATE_DIR="${GH_DASH_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/gh-dash}"

gh() {
  if [[ $# -eq 1 && $1 == dash ]]; then
    "$GH_DASH_HOME/bin/launch"
  else
    command gh "$@"
  fi
}
