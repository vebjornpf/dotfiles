# Interactive worktree manager — opens as tmux popup
wt() {
  tmux display-popup -w90% -h90% -E "~/.config/tmux/scripts/wt"
}
