# Switch to reviews tmux session, or run prs directly if already there
prs() {
  if [[ "$(tmux display -p '#{session_name}' 2>/dev/null)" == "reviews" ]]; then
    "$HOME/.config/tmux/scripts/prs"
  else
    bash "$HOME/.config/tmux/scripts/reviews-session"
  fi
}
