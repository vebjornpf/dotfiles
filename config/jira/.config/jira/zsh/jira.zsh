export JIRA_HOME="$HOME/.config/jira"
export JIRA_STATE_DIR="$HOME/git/daily/jira"

# Optional local overrides live outside stow-managed config.
# Supported variables:
#   JIRA_BASE_URL
#   JIRA_BOARD_URL
#   JIRA_BACKLOG_JQL
[[ -f "$HOME/.config/local/jira.zsh" ]] && source "$HOME/.config/local/jira.zsh"

local jira_bin_dir="$JIRA_HOME/bin"

if [[ -d "$jira_bin_dir" && ":$PATH:" != *":$jira_bin_dir:"* ]]; then
  path=("$jira_bin_dir" $path)
fi

_jira() {
  local -a top_level sync_targets mywork_commands board_commands
  local -a item_actions
  local completion_file
  local -a task_keys task_display
  local key task_status summary

  top_level=(backlog board mywork sync)
  board_commands=(open)
  sync_targets=(mywork backlog)
  mywork_commands=(list status)
  item_actions=(open cp cpk)
  completion_file="$JIRA_STATE_DIR/mywork-completion.tsv"

  case "${words[2]-}" in
    "")
      compadd -- $top_level
      ;;
    sync)
      if (( CURRENT == 3 )); then
        compadd -- $sync_targets
      fi
      ;;
    board)
      if (( CURRENT == 3 )); then
        compadd -- $board_commands
      fi
      ;;
    mywork)
      if (( CURRENT == 3 )); then
        compadd -J jira-mywork-commands -X 'Commands' -- "${mywork_commands[@]}"

        if [[ -f "$completion_file" ]]; then
          while IFS=$'\t' read -r key task_status summary; do
            [[ -z "$key" ]] && continue
            task_keys+=("$key")
            task_display+=("$key - $task_status - $summary")
          done < "$completion_file"

          if (( ${#task_keys[@]} > 0 )); then
            compadd -J jira-mywork-tasks -X 'My Tasks' -d task_display -- "${task_keys[@]}"
          fi
        fi
      elif [[ "${words[3]-}" == [A-Z][A-Z0-9]*-[0-9]* ]] && (( CURRENT >= 4 )); then
        compadd -- "${item_actions[@]}"
      fi
      ;;
  esac
}

compdef _jira jira
