# Interactive browser for PRs requesting my review across repositories
prs() {
  local fetch_cmd="bash $ZDOTDIR/scripts/assignedprs-grouped-render.sh"

  eval "$fetch_cmd" | fzf --ansi --prompt="Repos > " \
    --delimiter='\t' --with-nth=1 \
    --header=$'repo overview | alt-r: refresh' \
    --preview "bash $ZDOTDIR/scripts/assignedprs-grouped-preview.sh {4}" \
    --preview-window=up:75% \
    --bind 'alt-r:reload('"$fetch_cmd"')'
}
