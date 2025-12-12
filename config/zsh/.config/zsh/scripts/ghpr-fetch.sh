prs_json="$(gh pr list --limit 30 --json number,title,author,commits,reviews,statusCheckRollup,files,url)"
prs_json="${prs_json//\\n/ }"
echo "$prs_json" |
  jq -r '.[] | "\(.number)\t\(.author.login)\t\(.title)\t\(.|@base64)"'