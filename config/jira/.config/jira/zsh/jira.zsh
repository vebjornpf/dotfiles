export JIRA_HOME="$HOME/.config/jira"
export JIRA_STATE_DIR="$HOME/git/daily/jira"

# Optional local overrides live outside stow-managed config.
# Supported variables:
#   JIRA_PROJECT_KEY
#   JIRA_BASE_URL
#   JIRA_BOARD_URL
#   ATLASSIAN_SITE
#   ATLASSIAN_EMAIL
#   ATLASSIAN_API_TOKEN
[[ -f "$HOME/.config/local/tools.zsh" ]] && source "$HOME/.config/local/tools.zsh"

acli-jira-login() {
  jira auth "$@"
}

local jira_bin_dir="$JIRA_HOME/bin"

if [[ -d "$jira_bin_dir" && ":$PATH:" != *":$jira_bin_dir:"* ]]; then
  path=("$jira_bin_dir" $path)
fi

_jira() {
  local -a top_level sync_targets mywork_commands board_commands
  local -a create_types create_priorities create_options
  local -a create_available_options
  local -a create_option_descriptions create_available_option_descriptions
  local -a item_actions
  local item_completion_file mywork_completion_file epic_completion_file
  local -a task_keys task_display
  local -a epic_keys epic_display component_names
  local key task_status summary i current_token previous_token
  local jira_state_dir components_file
  local create_needs_value_for
  local has_summary_option has_component_option has_description_option has_assign_option

  top_level=(auth backlog board component create epics item mywork statusline sync)
  board_commands=(open)
  sync_targets=(all mywork)
  mywork_commands=(list status, sync)
  create_types=(Story Spike Bug)
  create_priorities=(Low Medium High)
  create_options=(--summary --component --description --assign)
  create_option_descriptions=(
    '--summary:work item summary'
    '--component:Jira component name'
    '--description:optional description text; otherwise $EDITOR opens at the end'
    '--assign:assign created item to me'
  )
  item_actions=(open cp cpk move)
  local -a move_statuses
  move_statuses=(backlog "in progress" qa done)
  item_completion_file="$JIRA_STATE_DIR/all-completion.tsv"
  mywork_completion_file="$JIRA_STATE_DIR/mywork-completion.tsv"
  epic_completion_file="$JIRA_STATE_DIR/epics-completion.tsv"
  jira_state_dir="${JIRA_STATE_DIR:-$HOME/git/daily/jira}"
  components_file="$jira_state_dir/components.tsv"

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
    create)
      if (( CURRENT == 3 )); then
        if [[ -f "$epic_completion_file" ]]; then
          while IFS=$'\t' read -r key task_status summary; do
            [[ -z "$key" ]] && continue
            epic_keys+=("$key")
            epic_display+=("$key - $task_status - $summary")
          done < "$epic_completion_file"

          if (( ${#epic_keys[@]} > 0 )); then
            compadd -J jira-create-epics -X 'Epics' -d epic_display -- "${epic_keys[@]}"
          fi
        fi
      elif (( CURRENT == 4 )); then
        if [[ "${words[3]-}" =~ '^[A-Z][A-Z0-9]*-[0-9]+$' ]]; then
          compadd -- "${create_types[@]}"
        fi
      elif (( CURRENT == 5 )); then
        if [[ "${words[4]-}" == (Story|Spike|Bug) ]]; then
          compadd -- "${create_priorities[@]}"
        fi
      else
        current_token="${words[CURRENT]-}"
        previous_token="${words[CURRENT-1]-}"
        create_needs_value_for=""
        has_summary_option=0
        has_component_option=0
        has_description_option=0
        has_assign_option=0

        for (( i = 6; i < CURRENT; i++ )); do
          key="${words[i]-}"
          if [[ -n "$create_needs_value_for" ]]; then
            create_needs_value_for=""
            continue
          fi

          case "$key" in
            --summary)
              has_summary_option=1
              create_needs_value_for="--summary"
              ;;
            --component)
              has_component_option=1
              create_needs_value_for="--component"
              ;;
            --description)
              has_description_option=1
              create_needs_value_for="--description"
              ;;
            --assign)
              has_assign_option=1
              ;;
          esac
        done

        case "$previous_token" in
          --component)
            if [[ -f "$components_file" ]]; then
              component_names=("${(@f)$(<"$components_file")}")
              (( ${#component_names[@]} > 0 )) && compadd -- "${component_names[@]}"
            fi
            ;;
          --summary|--description)
            ;;
          *)
            create_available_options=()
            create_available_option_descriptions=()
            (( ! has_summary_option )) && create_available_options+=(--summary)
            (( ! has_component_option )) && create_available_options+=(--component)
            (( ! has_description_option )) && create_available_options+=(--description)
            (( ! has_assign_option )) && create_available_options+=(--assign)

            for key in "${create_option_descriptions[@]}"; do
              case "$key" in
                --summary:*)
                  (( ! has_summary_option )) && create_available_option_descriptions+=("$key")
                  ;;
                --component:*)
                  (( ! has_component_option )) && create_available_option_descriptions+=("$key")
                  ;;
                --description:*)
                  (( ! has_description_option )) && create_available_option_descriptions+=("$key")
                  ;;
                --assign:*)
                  (( ! has_assign_option )) && create_available_option_descriptions+=("$key")
                  ;;
              esac
            done

            if [[ -n "$create_needs_value_for" ]]; then
              case "$create_needs_value_for" in
                --component)
                  if [[ -f "$components_file" ]]; then
                    component_names=("${(@f)$(<"$components_file")}")
                    (( ${#component_names[@]} > 0 )) && compadd -- "${component_names[@]}"
                  fi
                  ;;
                --summary|--description)
                  ;;
              esac
            else
              if [[ "$current_token" == --* || -z "$current_token" ]]; then
                _describe -t jira-create-options 'create options' create_available_option_descriptions
              fi
            fi
            ;;
        esac
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
