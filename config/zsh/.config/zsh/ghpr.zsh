# Interactive PR browser for current repo — opens as tmux popup
ghpr() {
  tmux display-popup -w90% -h90% -E "cd $PWD && $HOME/.config/tmux/ghpr"
}
