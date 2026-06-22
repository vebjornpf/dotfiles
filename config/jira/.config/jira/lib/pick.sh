#!/usr/bin/env bash

set -euo pipefail

JIRA_HOME="${JIRA_HOME:-$HOME/.config/jira}"
clipboard_lib="$HOME/.config/zsh/lib/clipboard.sh"
target="${1:-mywork}"
prompt_label="${2:-Jira My Work}"
list_script="$JIRA_HOME/lib/list.sh"
preview_script="$JIRA_HOME/lib/preview.sh"
sync_script="$JIRA_HOME/lib/sync.sh"

sync_target="$target"
assign_sync_targets="$target"
action_script="$JIRA_HOME/lib/action.sh"

case "$target" in
  backlog|epics|all)
    sync_target="all"
    assign_sync_targets="all mywork"
    ;;
esac

bash "$sync_script" $sync_target

while true; do
  selected=$(fzf --ansi --prompt="$prompt_label > " \
    --delimiter='\t' --with-nth=1 \
    --header=$'enter: open | alt-r: refresh | alt-a: assign me | alt-b: backlog | alt-p: in progress | alt-q: qa | alt-d: done | alt-c: copy key | alt-u: copy url' \
    --preview "bash $preview_script $target {6}" \
    --preview-window=up:75% \
    --bind "start:reload(bash $list_script $target)" \
    --bind "alt-r:reload(bash $sync_script $sync_target >/dev/null && bash $list_script $target)" \
    --bind "alt-a:execute-silent(bash $action_script assign-me {2})+reload(bash $sync_script $assign_sync_targets >/dev/null && bash $list_script $target)" \
    --bind "alt-b:execute-silent(bash $action_script transition {2} 'Backlog')+reload(bash $sync_script $assign_sync_targets >/dev/null && bash $list_script $target)" \
    --bind "alt-p:execute-silent(bash $action_script transition {2} 'In Progress')+reload(bash $sync_script $assign_sync_targets >/dev/null && bash $list_script $target)" \
    --bind "alt-q:execute-silent(bash $action_script transition {2} 'QA')+reload(bash $sync_script $assign_sync_targets >/dev/null && bash $list_script $target)" \
    --bind "alt-d:execute-silent(bash $action_script transition {2} 'Done')+reload(bash $sync_script $assign_sync_targets >/dev/null && bash $list_script $target)" \
    --bind "enter:execute-silent(acli jira workitem view {2} --web)+abort" \
    --bind "alt-c:execute-silent(bash -lc 'source \"\$0\"; printf %s \"\$1\" | clipboard_copy' \"$clipboard_lib\" {2})" \
    --bind "alt-u:execute-silent(bash -lc 'source \"\$0\"; printf %s \"\$1\" | clipboard_copy' \"$clipboard_lib\" {5})" )

  [[ -z "$selected" ]] && break
done
