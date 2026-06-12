#!/usr/bin/env bash

set -euo pipefail

JIRA_HOME="${JIRA_HOME:-$HOME/.config/jira}"
target="${1:-mywork}"
prompt_label="${2:-Jira My Work}"
list_script="$JIRA_HOME/lib/list.sh"
preview_script="$JIRA_HOME/lib/preview.sh"
sync_script="$JIRA_HOME/lib/sync.sh"

bash "$sync_script" "$target"

while true; do
  selected=$(fzf --ansi --prompt="$prompt_label > " \
    --delimiter='\t' --with-nth=1 \
    --header=$'enter: open in web | alt-r: refresh | alt-a: assign to me | alt-c: copy key | alt-u: copy url' \
    --preview "bash $preview_script $target {6}" \
    --preview-window=up:75% \
    --bind "start:reload(bash $list_script $target)" \
    --bind "alt-r:reload(bash $sync_script $target >/dev/null && bash $list_script $target)" \
    --bind "alt-a:execute-silent(acli jira workitem assign --key {2} --assignee @me --yes >/dev/null)+reload(bash $sync_script $target >/dev/null && bash $list_script $target)" \
    --bind "enter:execute-silent(acli jira workitem view {2} --web)+abort" \
    --bind "alt-c:execute-silent(printf '%s' {2} | xclip -selection clipboard)" \
    --bind "alt-u:execute-silent(printf '%s' {5} | xclip -selection clipboard)" )

  [[ -z "$selected" ]] && break
done
