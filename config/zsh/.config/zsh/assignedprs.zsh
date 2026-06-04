# Switch to daily tmux session prs window, or run prs directly if already there
prs() {
  if [[ "$(tmux display -p '#{session_name}' 2>/dev/null)" == "daily" && "$(tmux display -p '#{window_name}' 2>/dev/null)" == "prs" ]]; then
    "$HOME/.config/tmux/scripts/prs"
  else
    bash "$HOME/.config/tmux/scripts/reviews-session"
  fi
}
