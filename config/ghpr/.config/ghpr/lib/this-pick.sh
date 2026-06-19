#!/usr/bin/env bash

set -euo pipefail

GHPR_HOME="${GHPR_HOME:-$HOME/.config/ghpr}"
clipboard_lib="$HOME/.config/zsh/lib/clipboard.sh"

list_cmd="bash $GHPR_HOME/lib/this-list.sh"

while true; do
  selected=$(fzf --ansi --prompt="Repo PRs > " \
    --delimiter='\t' --with-nth=1,2,3 \
    --header=$'enter: open in nvim | alt-o: open in web | alt-a: approve | alt-m: merge | alt-d: toggle draft | alt-c: copy URL | alt-r: reload' \
    --preview "bash $GHPR_HOME/lib/this-preview.sh {4}" \
    --preview-window=up:75% \
    --phony --bind "start:reload($list_cmd)" \
    --bind "alt-r:reload($list_cmd)" \
    --bind "alt-o:execute-silent(gh pr view {1} --web)" \
    --bind "alt-a:execute-silent(gh pr review {1} --approve)+reload($list_cmd)" \
    --bind "alt-m:execute-silent(gh pr merge --squash {1})+reload($list_cmd)" \
    --bind "alt-d:execute-silent(bash -c 'draft=\$(gh pr view "\$1" --json isDraft -q .isDraft); if [[ "\$draft" == "true" ]]; then gh pr ready "\$1"; else gh pr ready --undo "\$1"; fi' -- {1})+reload($list_cmd)" \
    --bind "alt-c:execute-silent(bash -lc 'source \"\$0\"; gh pr view \"\$1\" --json url -q .url | clipboard_copy' \"$clipboard_lib\" {1})" \
    --expect=enter)

  line=$(printf '%s' "$selected" | tail -n +2)

  [[ -z "$line" ]] && break

  pr_number=$(printf '%s' "$line" | cut -f1)
  payload=$(printf '%s' "$line" | cut -f4)
  branch=$(printf '%s' "$payload" | base64 --decode | jq -r '.details.branches.head')

  bash "$GHPR_HOME/lib/open.sh" "" "$pr_number" "$branch"
  break
done
