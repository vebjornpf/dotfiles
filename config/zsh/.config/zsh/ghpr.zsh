# Interactive PR browser: shows approvals and commits, lets you open or merge PRs
ghpr() {
  fetch_cmd="bash $ZDOTDIR/scripts/ghpr-fetch.sh"
  fzf --ansi --prompt="Select PR > " \
    --delimiter='\t' --with-nth=1,2,3 \
    --header=$'alt-o: open in web | alt-b: checkout | alt-a: approve | alt-m: merge | alt-c: copy URL | alt-r: reload'  \
    --preview "bash $ZDOTDIR/scripts/ghpr-preview.sh {4}" \
    --preview-window=up:75% \
    --phony --bind "start:reload($fetch_cmd)" \
    --bind 'alt-r:reload('$fetch_cmd')' \
    --bind 'alt-b:execute(gh pr checkout {1})+abort' \
    --bind 'alt-o:execute-silent(gh pr view {1} --web)' \
    --bind 'alt-a:execute-silent(gh pr review {1} --approve)+reload('$fetch_cmd')' \
    --bind 'alt-m:execute-silent(gh pr merge --squash {1})+reload('$fetch_cmd')' \
    --bind 'alt-c:execute-silent(gh pr view {1} --json url -q .url | xclip -selection clipboard)'

}
