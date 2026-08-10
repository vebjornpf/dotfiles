#!/usr/bin/env bash

set -euo pipefail

lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$lib_dir/config.sh"
source "$lib_dir/views.sh"
source "$lib_dir/render.sh"

open_picker() {
  local view="$1"
  local selected key preview_command jira_command list_command

  require_jira_base_url
  preview_command="bash $(printf '%q' "$lib_dir/preview.sh") {2}"
  jira_command="$(printf '%q' "$JIRA_HOME/bin/jira")"
  list_command="bash $(printf '%q' "$lib_dir/picker-list.sh") $(printf '%q' "$view")"
  selected="$(bash "$lib_dir/picker-list.sh" "$view" | fzf --ansi --prompt="Jira ${view} > " --delimiter=$'\t' --with-nth=1 --header='enter: open web | alt-a: assign | alt-b: backlog | alt-p: in progress | alt-q: QA | alt-d: done | alt-c: copy key | alt-u: copy URL' --preview "$preview_command" --preview-window=up:50% --bind "enter:execute-silent($jira_command item {2} open)+abort" --bind "alt-a:execute-silent($jira_command item {2} assign && $jira_command sync >/dev/null)+reload($list_command)" --bind "alt-b:execute-silent($jira_command item {2} transition backlog && $jira_command sync >/dev/null)+reload($list_command)" --bind "alt-p:execute-silent($jira_command item {2} transition 'in progress' && $jira_command sync >/dev/null)+reload($list_command)" --bind "alt-q:execute-silent($jira_command item {2} transition qa && $jira_command sync >/dev/null)+reload($list_command)" --bind "alt-d:execute-silent($jira_command item {2} transition done && $jira_command sync >/dev/null)+reload($list_command)" --bind "alt-c:execute-silent($jira_command item {2} cpk)+abort" --bind "alt-u:execute-silent($jira_command item {2} cp)+abort" || true)"
  [[ -n "$selected" ]] || return 0
  key="$(printf '%s\n' "$selected" | cut -f2)"
  exec "$JIRA_HOME/bin/jira" item "$key" open
}
