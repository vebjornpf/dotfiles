# Depends on ~/.config/jira/bin/jira.

show_jira() {
  local index icon color text module

  index=$1
  icon="$(get_tmux_option "@catppuccin_jira_icon" "󰌃")"
  color="$(get_tmux_option "@catppuccin_jira_color" "$thm_teal")"
  text="$(get_tmux_option "@catppuccin_jira_text" "#($HOME/.config/jira/bin/jira statusline)")"

  module=$(build_status_module "$index" "$icon" "$color" "$text")

  echo "$module"
}
