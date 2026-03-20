filters_json="$(printf '%s\n' "$@" | jq -R . | jq -s .)"

search_args=(
  prs
  --author "@me"
  --state open
  --limit 100
)

search_args+=(
  --json
  author,body,commentsCount,createdAt,isDraft,isLocked,labels,number,repository,state,title,updatedAt,url
)

prs_json="$(gh search "${search_args[@]}")"
prs_json="${prs_json//\\n/ }"

echo "$prs_json" |
  jq -r --argjson filters "$filters_json" '
    .[] |
    (.repository.nameWithOwner | ascii_downcase) as $repo |
    ($filters | map(ascii_downcase)) as $needles |
    select(
      ($needles | length) == 0 or
      ($needles | map(. as $needle | ($repo | contains($needle))) | all)
    ) |
    @base64 as $b64 |
    "\(.repository.nameWithOwner)\t\(.number)\t\(if .isDraft then "DRAFT" else (.state | ascii_upcase) end)\t\(.title)\t\(.updatedAt)\t\($b64)"
  '
