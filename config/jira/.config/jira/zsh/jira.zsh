export JIRA_HOME="$HOME/.config/jira"
export JIRA_STATE_DIR="$HOME/git/daily/jira"

# Optional local overrides live outside stow-managed config.
# Supported variables include JIRA_PROJECT_KEY, JIRA_BASE_URL, and JIRA_ACCOUNT_ID.
[[ -f "$HOME/.config/local/tools.zsh" ]] && source "$HOME/.config/local/tools.zsh"

acli-jira-login() {
  jira auth "$@"
}

local jira_bin_dir="$JIRA_HOME/bin"
if [[ -d "$jira_bin_dir" && ":$PATH:" != *":$jira_bin_dir:"* ]]; then
  path=("$jira_bin_dir" $path)
fi

_jira() {
  local -a top_level scope_commands item_options epic_commands epic_subtask_commands create_types create_priorities create_options keys displays
  local key issue_status summary file epic_file previous_token

  top_level=(auth backlog board create doctor epics item me statusline sync team)
  scope_commands=(list status picker)
  epic_commands=(open subtasks)
  epic_subtask_commands=(list status)
  item_options=(assign transition open cp cpk --more --json)
  local -a transition_statuses
  transition_statuses=(backlog "in progress" qa done)
  create_types=(Story Spike Bug)
  create_priorities=(Low Medium High)
  create_options=(--summary --component --description --assign)

  if (( CURRENT == 2 )); then
    compadd -- "${top_level[@]}"
    return
  fi

  case "${words[2]-}" in
    team|me|backlog|epics)
      if (( CURRENT == 3 )); then
        compadd -- "${scope_commands[@]}"
        if [[ "${words[2]-}" == epics && -f "$JIRA_STATE_DIR/epics-completion.tsv" ]]; then
          while IFS=$'\t' read -r key issue_status summary; do
            [[ -n "$key" ]] && keys+=("$key") && displays+=("$key - $issue_status - $summary")
          done < "$JIRA_STATE_DIR/epics-completion.tsv"
          (( ${#keys[@]} > 0 )) && compadd -J jira-epic-keys -X 'Epics' -d displays -- "${keys[@]}"
        fi
        if [[ "${words[2]-}" == me && -f "$JIRA_STATE_DIR/me-completion.tsv" ]]; then
          while IFS=$'\t' read -r key issue_status summary; do
            [[ -n "$key" ]] && keys+=("$key") && displays+=("$key - $issue_status - $summary")
          done < "$JIRA_STATE_DIR/me-completion.tsv"
          (( ${#keys[@]} > 0 )) && compadd -J jira-me-issues -X 'Issues' -d displays -- "${keys[@]}"
        fi
      elif (( CURRENT == 4 )) && [[ "${words[3]-}" == list ]]; then
        compadd -- --json
      elif (( CURRENT == 4 )) && [[ "${words[2]-}" == epics && "${words[3]-}" =~ ^[A-Z][A-Z0-9]*-[0-9]+$ ]]; then
        compadd -- "${epic_commands[@]}"
      elif (( CURRENT == 5 )) && [[ "${words[2]-}" == epics && "${words[3]-}" =~ ^[A-Z][A-Z0-9]*-[0-9]+$ && "${words[4]-}" == subtasks ]]; then
        compadd -- "${epic_subtask_commands[@]}"
      elif (( CURRENT == 6 )) && [[ "${words[2]-}" == epics && "${words[3]-}" =~ ^[A-Z][A-Z0-9]*-[0-9]+$ && "${words[4]-}" == subtasks && "${words[5]-}" == list ]]; then
        compadd -- --json
      elif (( CURRENT == 4 )) && [[ "${words[3]-}" =~ ^[A-Z][A-Z0-9]*-[0-9]+$ ]]; then
        compadd -- "${item_options[@]}"
      elif (( CURRENT == 5 )) && [[ "${words[3]-}" =~ ^[A-Z][A-Z0-9]*-[0-9]+$ && "${words[4]-}" == transition ]]; then
        compadd -- "${transition_statuses[@]}"
      elif (( CURRENT == 5 )) && [[ "${words[3]-}" =~ ^[A-Z][A-Z0-9]*-[0-9]+$ && "${words[4]-}" == --more ]]; then
        compadd -- --json
      fi
      ;;
    item)
      if (( CURRENT == 3 )); then
        file="$JIRA_STATE_DIR/project-current.json"
        if [[ -f "$file" ]]; then
          while IFS=$'\t' read -r key issue_status summary; do
            [[ -n "$key" ]] && keys+=("$key") && displays+=("$key - $issue_status - $summary")
          done < <(jq -r '.items[]? | [(.key // ""), (.fields.status.name // ""), (.fields.summary // "")] | @tsv' "$file")
          (( ${#keys[@]} > 0 )) && compadd -J jira-item-issues -X 'Issues' -d displays -- "${keys[@]}"
        fi
      elif (( CURRENT == 4 )) && [[ "${words[3]-}" =~ ^[A-Z][A-Z0-9]*-[0-9]+$ ]]; then
        compadd -- "${item_options[@]}"
      elif (( CURRENT == 5 )) && [[ "${words[4]-}" == --more ]]; then
        compadd -- --json
      elif (( CURRENT == 5 )) && [[ "${words[4]-}" == transition ]]; then
        compadd -- "${transition_statuses[@]}"
      fi
      ;;
    doctor)
      (( CURRENT == 3 )) && compadd -- --json
      ;;
    create)
      if (( CURRENT == 3 )); then
        epic_file="$JIRA_STATE_DIR/epics-completion.tsv"
        if [[ -f "$epic_file" ]]; then
          while IFS=$'\t' read -r key issue_status summary; do
            [[ -n "$key" ]] && keys+=("$key") && displays+=("$key - $issue_status - $summary")
          done < "$epic_file"
          (( ${#keys[@]} > 0 )) && compadd -J jira-create-epics -X 'Epics' -d displays -- "${keys[@]}"
        fi
      elif (( CURRENT == 4 )) && [[ "${words[3]-}" =~ ^[A-Z][A-Z0-9]*-[0-9]+$ ]]; then
        compadd -- "${create_types[@]}"
      elif (( CURRENT == 5 )) && [[ "${words[4]-}" == (Story|Spike|Bug) ]]; then
        compadd -- "${create_priorities[@]}"
      elif (( CURRENT >= 6 )); then
        previous_token="${words[CURRENT-1]-}"
        case "$previous_token" in
          --summary|--component|--description)
            ;;
          *)
            compadd -- "${create_options[@]}"
            ;;
        esac
      fi
      ;;
  esac
}

compdef _jira jira
