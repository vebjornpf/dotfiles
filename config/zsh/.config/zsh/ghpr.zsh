# Interactive PR browser: shows approvals and commits, lets you open or merge PRs
ghpr() {
  prs_json="$(gh pr list --limit 30 \
    --json number,title,author,reviewDecision,commits,reviews,statusCheckRollup,files,url)"

  prs_json="${prs_json//\\n/ }"
  prs_keys="$(echo "$prs_json" \
    | jq 'map({key: (.number|tostring), value: .}) | from_entries')"

  prs_list="$(
    echo "$prs_json" |
    jq -r '.[] | "\(.number)\t[\(.reviewDecision)]\t\(.author.login)\t\(.title)"')"

  export prs_keys

  echo "$prs_list" | fzf --ansi --prompt="Select PR > " \
    --delimiter='\t' --with-nth=1,2,3,4 \
    --preview "bash $ZDOTDIR/scripts/ghpr-preview.sh {1}"
}