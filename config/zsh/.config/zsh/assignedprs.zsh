# Switch to reviews tmux session, or run prs directly if already there
prs() {
  if [[ "$(tmux display -p '#{session_name}' 2>/dev/null)" == "reviews" ]]; then
    "$HOME/.config/tmux/prs"
  else
    bash "$HOME/.config/tmux/reviews-session"
  fi
}
