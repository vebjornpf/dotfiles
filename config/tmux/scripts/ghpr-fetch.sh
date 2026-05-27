repo_arg="${1:-}"
repo_flag=""
if [[ -n "$repo_arg" ]]; then
  repo_flag="--repo $repo_arg"
fi

prs_json="$(gh pr list --limit 30 $repo_flag --json number,title,author,commits,reviews,statusCheckRollup,files,url)"
prs_json="${prs_json//\\n/ }"
echo "$prs_json" |
  jq -r '.[] | "\(.number)\t\(.author.login)\t\(.title)\t\(.|@base64)"'