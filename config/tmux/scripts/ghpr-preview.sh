b64="$1"

printf '%s' "$b64" | base64 --decode | jq -r '
  def c(code; s): "\u001b[" + code + "m" + s + "\u001b[0m";
  def green(s): c("32"; s);
  def yellow(s): c("33"; s);
  def red(s): c("31"; s);
  def cyan(s): c("36"; s);
  def bold(s): c("1"; s);
  def dim(s): c("2"; s);

  . as $p |
  [
    " " + bold("#\($p.number) ") + $p.title,
    " " + dim("author: ") + ($p.author.name // $p.author.login) + " (" + $p.author.login + ")",
    " " + dim("branch: ") + ($p.headRefName // "") + " → " + ($p.baseRefName // ""),
    " " + dim("url:    ") + $p.url,
    " " + dim("status: ") + (if $p.isDraft then yellow("DRAFT") else green("READY") end),
    " " + dim("merge:  ") + (
      if $p.mergeable == "CONFLICTING" then red("CONFLICTING")
      elif $p.mergeable == "MERGEABLE" then
        (if $p.mergeStateStatus == "CLEAN" then green("CLEAN")
         elif $p.mergeStateStatus == "BLOCKED" then yellow("BLOCKED")
         elif $p.mergeStateStatus == "BEHIND" then yellow("BEHIND")
         elif $p.mergeStateStatus == "UNSTABLE" then yellow("UNSTABLE")
         elif $p.mergeStateStatus == "DIRTY" then red("DIRTY")
         else yellow($p.mergeStateStatus // "UNKNOWN") end)
      else yellow("UNKNOWN") end),
    " " + dim("review: ") + (
      if $p.reviewDecision == "APPROVED" then green("APPROVED")
      elif $p.reviewDecision == "CHANGES_REQUESTED" then red("CHANGES_REQUESTED")
      elif $p.reviewDecision == "REVIEW_REQUIRED" then yellow("REVIEW_REQUIRED")
      else dim($p.reviewDecision // "NONE") end),
    "",
    "Status checks:",
    (if ($p.statusCheckRollup|length)>0 then
       ($p.statusCheckRollup[]
        | "- " + .context + ": " +
          (if .state=="SUCCESS" then green(.state)
           elif .state=="PENDING" then yellow(.state)
           else red(.state) end) +
          (if .targetUrl then
              "\n" + .targetUrl
           else "" end))
     else "- none" end),
    "",
    "Commits:",
    ($p.commits | map("- " + .oid[0:7] + " " + .messageHeadline) | .[]),
    "",
    "Reviews:",
    (if ($p.reviews|length)>0 then
       ($p.reviews[]
        | "- " + .author.login + ": " + .state +
          (if .commit.oid then " @" + (.commit.oid[0:7]) else "" end))
     else "- none" end),
    "",
    "Files:",
    ($p.files | map("- " + .path + " (+" + (.additions|tostring) + "/-" + (.deletions|tostring) + ")") | .[])
  ]
  | .[]
  '
