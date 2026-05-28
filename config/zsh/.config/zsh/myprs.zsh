# Switch to myprs tmux session, or run myprs directly if already there
myprs() {
  if [[ "$(tmux display -p '#{session_name}' 2>/dev/null)" == "myprs" ]]; then
    "$HOME/.config/tmux/myprs"
  else
    bash "$HOME/.config/tmux/myprs-session"
  fi
}
