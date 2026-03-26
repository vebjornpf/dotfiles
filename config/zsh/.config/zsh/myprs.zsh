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
    --delimiter='\t' --with-nth=1 \
    --header=$'alt-o: open in web | alt-c: copy URL | alt-i: merge info | alt-d: toggle draft | alt-m: merge | alt-r: refresh' \
    --preview "bash $ZDOTDIR/scripts/myprs-preview.sh {2} {3} {4} {5} {6} {7} {8} {9} {10} {11} {12} {13}" \
    --preview-window=up:75% \
    --bind 'alt-o:execute-silent(gh pr view {3} --repo {2} --web)' \
    --bind 'alt-c:execute-silent(printf "%s" {7} | xclip -selection clipboard)' \
    --bind 'alt-d:execute-silent(bash '"$ZDOTDIR"'/scripts/myprs-toggle-draft.sh {2} {3} {4})+reload('"$fetch_cmd"')' \
    --bind 'alt-m:execute-silent(gh pr merge --repo {2} --squash {3})+reload('"$fetch_cmd"')' \
    --bind 'alt-r:reload('"$fetch_cmd"')' \
    --bind 'alt-i:execute(bash '"$ZDOTDIR"'/scripts/myprs-merge-info.sh {2} {3})'
}
