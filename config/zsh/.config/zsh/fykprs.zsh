# Interactive browser for open PRs in the Fyk-konsulenter org
fykprs() {
  local filters=("$@")
  local fetch_cmd
  if (( ${#filters[@]} > 0 )); then
    fetch_cmd="bash $ZDOTDIR/scripts/fykprs-fetch.sh"
    local filter
    for filter in "${filters[@]}"; do
      fetch_cmd+=" $(printf '%q' "$filter")"
    done
  else
    fetch_cmd="bash $ZDOTDIR/scripts/fykprs-fetch.sh"
  fi

  eval "$fetch_cmd" | fzf --ansi --prompt="Fyk PRs > " \
    --delimiter='\t' --with-nth=1 \
    --header=$'alt-o: open in web | alt-r: refresh' \
    --preview "bash $ZDOTDIR/scripts/assignedprs-preview.sh {2} {3} {4} {5} {6} {7} {8}" \
    --preview-window=up:75% \
    --bind 'alt-o:execute-silent(gh pr view {3} --repo {2} --web)' \
    --bind 'alt-r:reload('"$fetch_cmd"')'
}
