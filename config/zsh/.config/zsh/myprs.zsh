# Interactive PR browser for PRs authored by me — opens as tmux popup
myprs() {
  tmux display-popup -w90% -h90% -E "$HOME/.config/tmux/myprs"
}
