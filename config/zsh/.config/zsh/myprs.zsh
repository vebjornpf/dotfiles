# Switch to daily tmux session myprs window, or run myprs directly if already there
myprs() {
  if [[ "$(tmux display -p '#{session_name}' 2>/dev/null)" == "daily" && "$(tmux display -p '#{window_name}' 2>/dev/null)" == "myprs" ]]; then
    "$HOME/.config/tmux/scripts/myprs"
  else
    bash "$HOME/.config/tmux/scripts/myprs-session"
  fi
}
