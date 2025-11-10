num="$1"
pr=$(jq -r ".\"$num\"" <<<"$prs_keys")
echo "$num"
echo "$pr" | jq