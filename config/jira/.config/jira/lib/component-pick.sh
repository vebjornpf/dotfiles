#!/usr/bin/env bash

set -euo pipefail

JIRA_HOME="${JIRA_HOME:-$HOME/.config/jira}"
clipboard_lib="$HOME/.config/zsh/lib/clipboard.sh"
list_script="$JIRA_HOME/lib/component-list.sh"
preview_script="$JIRA_HOME/lib/preview.sh"
env_script="$JIRA_HOME/lib/env.sh"
action_script="$JIRA_HOME/lib/action.sh"
components_file="${JIRA_STATE_DIR:-$HOME/git/daily/jira}/components.tsv"

source "$env_script"

if [[ ! -f "$components_file" ]]; then
  echo "No component list found. Run: jira component sync" >&2
  exit 1
fi

component_name="$(cat "$components_file" | fzf --prompt='Jira Component > ' --height=60% --layout=reverse)"

[[ -z "$component_name" ]] && exit 0

while true; do
  selected="$(bash "$list_script" "$component_name" | fzf --ansi --prompt="${component_name} > " \
    --delimiter='\t' --with-nth=1 \
    --header=$'enter: open in web | alt-r: refresh | alt-a: assign to me | alt-b: backlog | alt-p: in progress | alt-q: qa | alt-d: done | alt-c: copy key | alt-u: copy url' \
    --preview "bash $preview_script component {6}" \
    --preview-window=up:75% \
    --bind "alt-r:reload(bash $list_script $(printf '%q' "$component_name"))" \
    --bind "alt-a:execute-silent(bash $action_script assign-me {2})+reload(bash $list_script $(printf '%q' "$component_name"))" \
    --bind "alt-b:execute-silent(bash $action_script transition {2} 'Backlog')+reload(bash $list_script $(printf '%q' "$component_name"))" \
    --bind "alt-p:execute-silent(bash $action_script transition {2} 'In Progress')+reload(bash $list_script $(printf '%q' "$component_name"))" \
    --bind "alt-q:execute-silent(bash $action_script transition {2} 'QA')+reload(bash $list_script $(printf '%q' "$component_name"))" \
    --bind "alt-d:execute-silent(bash $action_script transition {2} 'Done')+reload(bash $list_script $(printf '%q' "$component_name"))" \
    --bind "enter:execute-silent(acli jira workitem view {2} --web)+abort" \
    --bind "alt-c:execute-silent(bash -lc 'source \"\$0\"; printf %s \"\$1\" | clipboard_copy' \"$clipboard_lib\" {2})" \
    --bind "alt-u:execute-silent(bash -lc 'source \"\$0\"; printf %s \"\$1\" | clipboard_copy' \"$clipboard_lib\" {5})")"

  [[ -z "$selected" ]] && break
done
