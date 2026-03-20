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

gh search "${search_args[@]}" |
  jq -r --argjson filters "$filters_json" '
    .[] |
    (.repository.nameWithOwner | ascii_downcase) as $repo |
    ($filters | map(ascii_downcase)) as $needles |
    select(
      ($needles | length) == 0 or
      ($needles | map(. as $needle | ($repo | contains($needle))) | all)
    ) |
    (.repository.nameWithOwner) as $repo_name |
    (.number | tostring) as $number |
    (if .isDraft then "DRAFT" else (.state | ascii_upcase) end) as $state |
    (.title | gsub("[\r\n\t]+"; " ")) as $title |
    (.updatedAt | sub("T"; " ") | sub("Z$"; "")) as $updated |
    (.url) as $url |
    ((.author.name // .author.login) + " (" + .author.login + ")") as $author |
    (.createdAt | sub("T"; " ") | sub("Z$"; "")) as $created |
    (.commentsCount | tostring) as $comments |
    (if .isLocked then "yes" else "no" end) as $locked |
    (if (.labels | length) > 0 then (.labels | map(.name) | join(", ")) else "none" end) as $labels |
    (.body // "" | @base64) as $body |
    "\($repo_name)\t\($number)\t\($state)\t\($title)\t\($updated)\t\($url)\t\($author)\t\($created)\t\($comments)\t\($locked)\t\($labels)\t\($body)"
  ' |
  awk -F '\t' '
    function trunc(s, n) {
      return length(s) > n ? substr(s, 1, n - 3) "..." : s
    }
    {
      repo = sprintf("%-32s", trunc($1, 32))
      state = sprintf("%-7s", $3)
      title = sprintf("%-96s", trunc($4, 96))
      display = repo "  " state "  " title
      print display "\t" $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5 "\t" $6 "\t" $7 "\t" $8 "\t" $9 "\t" $10 "\t" $11 "\t" $12
    }
  '
