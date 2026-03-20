repo="$1"
number="$2"

if [[ -z "$repo" || -z "$number" ]]; then
  echo "Missing repo or PR number" >&2
  exit 1
fi

if ! pr_json="$(gh pr view "$number" --repo "$repo" --json title,url,isDraft,mergeable,mergeStateStatus,reviewDecision,statusCheckRollup 2>/dev/null)"; then
  echo "Unable to load merge details for $repo#$number" >&2
  exit 1
fi

clear

printf '%s' "$pr_json" | jq -r --arg repo "$repo" --arg number "$number" '
  def c(code; s): "\u001b[" + code + "m" + s + "\u001b[0m";
  def bold(s): c("1"; s);
  def dim(s): c("2"; s);
  def green(s): c("32"; s);
  def yellow(s): c("33"; s);
  def red(s): c("31"; s);
  def state_color(s):
    if s == "MERGEABLE" or s == "OPEN" or s == "APPROVED" or s == "SUCCESS" or s == "CLEAN" then green(s)
    elif s == "UNKNOWN" or s == "PENDING" or s == "REVIEW_REQUIRED" then yellow(s)
    else red(s)
    end;

  . as $p |
  [
    bold($p.title),
    dim($repo + "#" + $number),
    "",
    "draft              " + (if $p.isDraft then yellow("yes") else green("no") end),
    "mergeable          " + state_color(($p.mergeable // "UNKNOWN") | ascii_upcase),
    "merge state        " + state_color(($p.mergeStateStatus // "UNKNOWN") | ascii_upcase),
    "review decision    " + state_color(($p.reviewDecision // "UNKNOWN") | ascii_upcase),
    "url                " + $p.url,
    "",
    "Status checks:",
    (if ($p.statusCheckRollup | length) > 0 then
      ($p.statusCheckRollup[]
       | "  - " + .context + ": " + state_color((.state // "UNKNOWN") | ascii_upcase))
     else
      "  - none"
     end),
    "",
    dim("Press m to merge, any other key to return")
  ] | .[]'

IFS= read -rsn1 key
printf '\n'

if [[ "$key" == "m" || "$key" == "M" ]]; then
  gh pr merge --repo "$repo" --squash "$number"
fi
