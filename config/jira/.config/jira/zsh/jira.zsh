export JIRA_HOME="$HOME/.config/jira"
export JIRA_STATE_DIR="$HOME/git/daily/jira"

# Optional local overrides live outside stow-managed config.
# Supported variables:
#   JIRA_PROJECT_KEY
#   JIRA_BASE_URL
#   JIRA_BOARD_URL
[[ -f "$HOME/.config/local/jira.zsh" ]] && source "$HOME/.config/local/jira.zsh"

local jira_bin_dir="$JIRA_HOME/bin"

if [[ -d "$jira_bin_dir" && ":$PATH:" != *":$jira_bin_dir:"* ]]; then
  path=("$jira_bin_dir" $path)
fi

_jira() {
  local -a top_level sync_targets mywork_commands board_commands create_commands
  local -a item_actions
  local item_completion_file mywork_completion_file
  local -a task_keys task_display
  local key task_status summary

  top_level=(backlog board component create item mywork statusline sync)
  create_commands=()
  board_commands=(open)
  sync_targets=(all mywork)
  mywork_commands=(list status, sync)
  item_actions=(open cp cpk move)
  local -a move_statuses
  move_statuses=(backlog "in progress" qa done)
  item_completion_file="$JIRA_STATE_DIR/all-completion.tsv"
  mywork_completion_file="$JIRA_STATE_DIR/mywork-completion.tsv"

  if (( CURRENT == 2 )); then
    compadd -- "${top_level[@]}"
    return
  fi

  case "${words[2]-}" in
    sync)
      if (( CURRENT == 3 )); then
        compadd -- "${sync_targets[@]}"
      fi
      ;;
    board)
      if (( CURRENT == 3 )); then
        compadd -- "${board_commands[@]}"
      fi
      ;;
    component)
      if (( CURRENT == 3 )); then
        compadd -- sync
      fi
      ;;
    item)
      if (( CURRENT == 3 )); then
        if [[ -f "$item_completion_file" ]]; then
          while IFS=$'\t' read -r key task_status summary; do
            [[ -z "$key" ]] && continue
            task_keys+=("$key")
            task_display+=("$key - $task_status - $summary")
          done < "$item_completion_file"

          if (( ${#task_keys[@]} > 0 )); then
            compadd -J jira-item-tasks -X 'Tasks' -d task_display -- "${task_keys[@]}"
          fi
        fi
      elif (( CURRENT == 4 )); then
        if [[ "${words[3]-}" =~ '^[A-Z][A-Z0-9]*(-[0-9]*)?$' ]]; then
          compadd -- "${item_actions[@]}"
        fi
      elif (( CURRENT == 5 )); then
        if [[ "${words[4]-}" == "move" ]]; then
          compadd -- "${move_statuses[@]}"
        fi
      fi
      ;;
    mywork)
      if (( CURRENT == 3 )); then
        compadd -J jira-mywork-commands -X 'Commands' -- "${mywork_commands[@]}"
        if [[ -f "$mywork_completion_file" ]]; then
          while IFS=$'\t' read -r key task_status summary; do
            [[ -z "$key" ]] && continue
            task_keys+=("$key")
            task_display+=("$key - $task_status - $summary")
          done < "$mywork_completion_file"

          if (( ${#task_keys[@]} > 0 )); then
            compadd -J jira-mywork-tasks -X 'My Tasks' -d task_display -- "${task_keys[@]}"
          fi
        fi
      elif (( CURRENT == 4 )) && [[ -f "$mywork_completion_file" ]]; then
        if [[ "${words[3]-}" =~ '^[A-Z][A-Z0-9]*(-[0-9]*)?$' ]]; then
          compadd -- "${item_actions[@]}"
        fi
      elif (( CURRENT == 5 )); then
        if [[ "${words[4]-}" == "move" ]]; then
          compadd -- "${move_statuses[@]}"
        fi
      fi
      ;;
  esac
}

compdef _jira jira
