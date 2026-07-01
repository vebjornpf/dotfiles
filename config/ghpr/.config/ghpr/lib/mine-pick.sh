#!/usr/bin/env bash

set -euo pipefail

GHPR_HOME="${GHPR_HOME:-$HOME/.config/ghpr}"
source "$GHPR_HOME/lib/common.sh"
clipboard_lib="$HOME/.config/zsh/lib/clipboard.sh"
tmux_sessionizer="$HOME/.config/tmux/scripts/tmux-sessionizer"

list_cmd="bash $GHPR_HOME/lib/mine-list.sh"
reload_cmd="$GHPR_HOME/bin/ghpr-sync mine >/dev/null && bash $GHPR_HOME/lib/mine-list.sh"

while true; do
  selected=$(fzf --ansi --prompt="My PRs > " \
    --delimiter='\t' --with-nth=1,2,3 \
    --header=$'enter: tmux repo session | alt-o: open in web | alt-a: approve | alt-m: merge | alt-d: toggle draft | alt-c: copy URL | alt-r: reload' \
    --preview "bash $GHPR_HOME/lib/mine-preview.sh {2} {1}" \
    --preview-window=up:75% \
    --phony --bind "start:reload($list_cmd)" \
    --bind "alt-r:reload($reload_cmd)" \
    --bind "alt-o:execute-silent(gh pr view {1} --repo {2} --web)" \
    --bind "alt-a:execute-silent(gh pr review {1} --repo {2} --approve)+reload($reload_cmd)" \
    --bind "alt-m:execute-silent(gh pr merge --squash --repo {2} {1})+reload($reload_cmd)" \
    --bind "alt-d:execute-silent(bash -c 'draft=\$(bash "$GHPR_HOME/lib/mine-item.sh" "\$1" "\$2" | jq -r ".details.state.is_draft"); if [[ "\$draft" == "true" ]]; then gh pr ready "\$2" --repo "\$1"; else gh pr ready --undo "\$2" --repo "\$1"; fi' -- {2} {1})+reload($reload_cmd)" \
    --bind "alt-c:execute-silent(bash -lc 'source \"\$0\"; gh pr view \"\$1\" --repo \"\$2\" --json url -q .url | clipboard_copy' \"$clipboard_lib\" {1} {2})" \
    --expect=enter)

  line=$(printf '%s' "$selected" | sed -n '2p')

  [[ -z "$line" ]] && break

  repo=$(printf '%s' "$line" | cut -f2)
  clone_path="$(repo_clone_path "$repo")"

  ensure_repo_clone "$repo"
  bash "$tmux_sessionizer" "$clone_path"
  break
done
