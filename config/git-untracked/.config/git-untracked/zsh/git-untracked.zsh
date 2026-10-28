export GIT_UNTRACKED_HOME="$HOME/.config/git-untracked"
export GIT_UNTRACKED_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/git-untracked"

local git_untracked_bin_dir="$GIT_UNTRACKED_HOME/bin"
if [[ -d "$git_untracked_bin_dir" && ":$PATH:" != *":$git_untracked_bin_dir:"* ]]; then
  path=("$git_untracked_bin_dir" $path)
fi
