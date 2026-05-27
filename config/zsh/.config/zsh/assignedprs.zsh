# Interactive browser for PRs requesting my review — opens as tmux popup
prs() {
  tmux display-popup -w90% -h90% -E "$HOME/.config/tmux/prs"
}
