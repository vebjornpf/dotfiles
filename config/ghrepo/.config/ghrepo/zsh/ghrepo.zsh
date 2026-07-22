export GHREPO_HOME="$HOME/.config/ghrepo"
export GHREPO_STATE_DIR="$HOME/git/daily/ghrepo"

# Optional local overrides live outside stow-managed config.
# Supported variables:
#   GHREPO_ORG
[[ -f "$HOME/.config/local/tools.zsh" ]] && source "$HOME/.config/local/tools.zsh"

local ghrepo_bin_dir="$GHREPO_HOME/bin"

if [[ -d "$ghrepo_bin_dir" && ":$PATH:" != *":$ghrepo_bin_dir:"* ]]; then
  path=("$ghrepo_bin_dir" $path)
fi

_ghrepo() {
  local -a top_level

  top_level=(sync)

  if (( CURRENT == 2 )); then
    compadd -- "${top_level[@]}"
  fi
}

compdef _ghrepo ghrepo
