# Interactive browser for PRs authored by me across repositories
myprs() {
  local filters=("$@")
  local fetch_cmd
  if (( ${#filters[@]} > 0 )); then
    fetch_cmd="bash $ZDOTDIR/scripts/myprs-fetch.sh"
    local filter
    for filter in "${filters[@]}"; do
      fetch_cmd+=" $(printf '%q' "$filter")"
    done
  else
    fetch_cmd="bash $ZDOTDIR/scripts/myprs-fetch.sh"
  fi

  eval "$fetch_cmd" | fzf --ansi --prompt="My PRs > " \
    --delimiter='\t' --with-nth=1,2,3,4 \
    --header=$'alt-o: open in web | alt-c: copy URL | alt-m: merge | alt-d: toggle draft | alt-r: refresh' \
    --preview "bash $ZDOTDIR/scripts/myprs-preview.sh {6}" \
    --preview-window=up:75% \
    --bind 'alt-o:execute-silent(gh pr view {2} --repo {1} --web)' \
    --bind 'alt-c:execute-silent(printf "%s" {6} | base64 --decode | jq -r .url | xclip -selection clipboard)' \
    --bind 'alt-d:execute(bash '"$ZDOTDIR"'/scripts/myprs-toggle-draft.sh {1} {2} {3})+reload('"$fetch_cmd"')' \
    --bind 'alt-r:reload('"$fetch_cmd"')' \
    --bind 'alt-m:execute-silent(gh pr merge --repo {1} --squash {2})+reload('"$fetch_cmd"')'
}
