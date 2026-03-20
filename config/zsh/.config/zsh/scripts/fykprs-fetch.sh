filters_json="$(printf '%s\n' "$@" | jq -R . | jq -s .)"

search_args=(
  prs
  --owner Fyk-konsulenter
  --state=open
)

search_args+=(
  --json
  author,body,commentsCount,createdAt,isDraft,isLocked,labels,number,repository,state,title,updatedAt,url
)

gh search "${search_args[@]}" |
  jq -r --argjson filters "$filters_json" '
    .[] |
    (.repository.nameWithOwner) as $repo |
    ($filters | map(ascii_downcase)) as $needles |
    select(
      ($needles | length) == 0 or
      ($needles | map(. as $needle | ($repo | ascii_downcase | contains($needle))) | all)
    ) |
    (.number | tostring) as $number |
    (.author.login) as $author |
    (.title | gsub("[\r\n\t]+"; " ")) as $title |
    (.updatedAt | sub("T"; " ") | sub("Z$"; "")) as $updated |
    (.url) as $url |
    (.body // "" | @base64) as $body |
    "\($repo)\t\($number)\t\($author)\t\($title)\t\($updated)\t\($url)\t\($body)"
  ' |
  awk -F '\t' '
    function trunc(s, n) {
      return length(s) > n ? substr(s, 1, n - 3) "..." : s
    }
    {
      repo = sprintf("%-32s", trunc($1, 32))
      author = sprintf("%-18s", trunc($3, 18))
      title = sprintf("%-90s", trunc($4, 90))
      display = repo "  " author "  " title
      print display "\t" $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5 "\t" $6 "\t" $7
    }
  '
