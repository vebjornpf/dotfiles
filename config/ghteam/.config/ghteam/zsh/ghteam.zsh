export GHTEAM_HOME="$HOME/.config/ghteam"
export GHTEAM_STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/ghteam"

if [[ -d "$GHTEAM_HOME/bin" && ":$PATH:" != *":$GHTEAM_HOME/bin:"* ]]; then
  path=("$GHTEAM_HOME/bin" $path)
fi
