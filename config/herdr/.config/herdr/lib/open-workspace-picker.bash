open_workspace_picker_list() {
  herdr workspace list |
    jq -r '.result.workspaces[]? | [.workspace_id, .label, .focused] | @tsv'
}

open_workspace_picker_close() {
  local workspace_id=$1 workspaces focused replacement message
  local header='enter: focus | ctrl-x: close (keeps last workspace) | esc: cancel'

  if ! workspaces=$(herdr workspace list 2>&1); then
    printf 'Could not list workspaces: %s\n%s\n' "$workspaces" "$header"
    return
  fi

  if ! jq -e --arg id "$workspace_id" \
    '.result.workspaces | any(.workspace_id == $id)' <<< "$workspaces" >/dev/null; then
    printf 'Workspace is no longer open\n%s\n' "$header"
    return
  fi

  if [[ $(jq '.result.workspaces | length' <<< "$workspaces") -le 1 ]]; then
    printf 'Keeping the last workspace open\n%s\n' "$header"
    return
  fi

  focused=$(jq -r '.result.workspaces[] | select(.focused) | .workspace_id' <<< "$workspaces")
  if [[ "$workspace_id" == "$focused" ]]; then
    replacement=$(jq -r --arg id "$workspace_id" \
      'first(.result.workspaces[] | select(.workspace_id != $id)) | .workspace_id' <<< "$workspaces")
    # Popups are session-modal: move the underlying focus before closing its workspace.
    if ! message=$(herdr workspace focus "$replacement" 2>&1); then
      printf 'Could not switch workspace: %s\n%s\n' "$message" "$header"
      return
    fi
  fi

  if ! message=$(herdr workspace close "$workspace_id" 2>&1); then
    printf 'Could not close workspace: %s\n%s\n' "$message" "$header"
    return
  fi
  printf '%s\n' "$header"
}

open_workspace_picker() {
  local command workspace_data selected picker

  for command in fzf herdr jq; do
    if ! command -v "$command" >/dev/null 2>&1; then
      printf 'open-workspace-picker: %s is required\n' "$command" >&2
      return 1
    fi
  done

  case ${1:-} in
    --list) open_workspace_picker_list; return ;;
    --close) open_workspace_picker_close "$2"; return ;;
  esac

  workspace_data=$(open_workspace_picker_list)
  [[ -n "$workspace_data" ]] || return 0

  # Quote the callback path for fzf's shell, including installations with spaces.
  printf -v picker '%q' "$(dirname -- "${BASH_SOURCE[0]}")/../bin/open-workspace-picker"
  if selected=$(printf '%s\n' "$workspace_data" | fzf \
    --delimiter=$'\t' \
    --with-nth=2 \
    --prompt='workspaces > ' \
    --border=rounded \
    --border-label=' open workspaces ' \
    --header='enter: focus | ctrl-x: close (keeps last workspace) | esc: cancel' \
    --header-first \
    --info=inline-right \
    --no-scrollbar \
    --cycle \
    --bind="ctrl-x:transform-header($picker --close {1})+reload($picker --list)"); then
    [[ -n "$selected" ]] || return 0
    herdr workspace focus "${selected%%$'\t'*}" >/dev/null
  else
    local status=$?
    # No selection and cancellation are normal exits, not popup failures.
    [[ $status -eq 1 || $status -eq 130 ]] && return 0
    return "$status"
  fi
}
