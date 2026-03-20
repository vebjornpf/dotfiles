# Interactive browser for PRs requesting my review across repositories
prs() {
  local filters=("$@")
  local fetch_cmd
  if (( ${#filters[@]} > 0 )); then
    fetch_cmd="bash $ZDOTDIR/scripts/assignedprs-fetch.sh"
    local filter
    for filter in "${filters[@]}"; do
      fetch_cmd+=" $(printf '%q' "$filter")"
    done
  else
    fetch_cmd="bash $ZDOTDIR/scripts/assignedprs-fetch.sh"
  fi

  eval "$fetch_cmd" | fzf --ansi --prompt="PRs > " \
    --delimiter='\t' --with-nth=1 \
    --header=$'alt-o: open in web | alt-c: copy URL | alt-a: approve | alt-m: merge | alt-i: merge info | alt-r: refresh' \
    --preview "bash $ZDOTDIR/scripts/assignedprs-preview.sh {2} {3} {4} {5} {6} {7} {8}" \
    --preview-window=up:75% \
    --bind 'alt-o:execute-silent(gh pr view {3} --repo {2} --web)' \
    --bind 'alt-c:execute-silent(printf "%s" {7} | xclip -selection clipboard)' \
    --bind 'alt-a:execute-silent(gh pr review {3} --repo {2} --approve)+reload('"$fetch_cmd"')' \
    --bind 'alt-r:reload('"$fetch_cmd"')' \
    --bind 'alt-m:execute-silent(gh pr merge --repo {2} --squash {3})+reload('"$fetch_cmd"')' \
    --bind 'alt-i:execute(bash '"$ZDOTDIR"'/scripts/myprs-merge-info.sh {2} {3})'
}
