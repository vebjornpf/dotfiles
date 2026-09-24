#!/usr/bin/env bash

set -euo pipefail

GHPR_HOME="${GHPR_HOME:-$HOME/.config/ghpr}"
repo="${1:-}"
number="${2:-}"
session="${3:-}"
author="${4:-}"
updated="${5:-}"
state="${6:-}"
title="${7:-}"
url="${8:-}"
wrap_width="${FZF_PREVIEW_COLUMNS:-100}"

if [[ "$wrap_width" -lt 30 ]]; then
  wrap_width=100
fi

detail_file="$session/details/$repo/$number.json"
if [[ ! -f "$detail_file" ]]; then
  jq -nr --arg number "$number" --arg title "$title" --arg repo "$repo" \
    --arg author "$author" --arg updated "$updated" --arg state "$state" --arg url "$url" '
      "#\($number) \($title)",
      "repo:     \($repo)",
      "author:   \($author)",
      "state:    \($state | ascii_upcase)",
      "updated:  \($updated)",
      "url:      \($url)",
      "",
      "Press Alt-P to fetch the full preview."
    ' | fold -s -w "$wrap_width"
  exit
fi

jq -r '
  def c(code; value): "\u001b[" + code + "m" + value + "\u001b[0m";
  def green(value): c("32"; value);
  def yellow(value): c("33"; value);
  def red(value): c("31"; value);
  def bold(value): c("1"; value);
  def dim(value): c("2"; value);
  def value_or_na(value): if value == null or value == "" then "not available" else value end;
  def review_name: .author.login // .author.name // "unknown";
  def check_name: .name // .context // .workflowName // "unknown check";
  def check_state: .conclusion // .state // .status // "UNKNOWN";
  def check_url: .detailsUrl // .targetUrl // "";
  def state_color(value):
    if value == "SUCCESS" or value == "COMPLETED" or value == "APPROVED" or value == "MERGEABLE" or value == "CLEAN" then green(value)
    elif value == "PENDING" or value == "IN_PROGRESS" or value == "QUEUED" or value == "REVIEW_REQUIRED" then yellow(value)
    else red(value) end;

  . as $pr |
  [
    bold("#\($pr.number) \($pr.title)"),
    dim("repo:     ") + $pr.repository,
    dim("author:   ") + ($pr.author.login // "unknown"),
    dim("state:    ") + (if $pr.isDraft then yellow("DRAFT") else green("READY") end),
    dim("review:   ") + state_color(value_or_na($pr.reviewDecision)),
    dim("merge:    ") + state_color(value_or_na($pr.mergeable)) + "/" + value_or_na($pr.mergeStateStatus),
    dim("branches: ") + value_or_na($pr.headRefName) + " -> " + value_or_na($pr.baseRefName),
    dim("changes:  ") + "+" + ($pr.additions | tostring) + "/-" + ($pr.deletions | tostring) + " across " + ($pr.changedFiles | tostring) + " files",
    dim("labels:   ") + (if ($pr.labels | length) > 0 then ($pr.labels | map(.name) | join(", ")) else "none" end),
    dim("url:      ") + $pr.url,
    "",
    bold("Body"),
    (if ($pr.body // "") == "" then dim("No description") else $pr.body end),
    "",
    bold("Review requested"),
    (if ($pr.reviewRequests | length) > 0 then
       ($pr.reviewRequests[] | "- " + (.login // .name // .slug // "unknown"))
     else dim("- none") end),
    "",
    bold("Checks"),
    (if ($pr.statusCheckRollup | length) > 0 then
       ($pr.statusCheckRollup[] |
         "- " + check_name + ": " + state_color(check_state) +
         (if check_url == "" then "" else "\n  " + check_url end))
     else dim("- none") end),
    "",
    bold("Latest reviews"),
    (if ($pr.latestReviews | length) > 0 then
       ($pr.latestReviews[] | "- " + review_name + ": " + state_color(.state // "UNKNOWN"))
     else dim("- none") end),
    "",
    bold("Commits"),
    (if ($pr.commits | length) > 0 then
       ($pr.commits[] | "- " + (.oid[0:7]) + " " + (.messageHeadline // ""))
     else dim("- none") end),
    "",
    bold("Files"),
    (if ($pr.files | length) > 0 then
       ($pr.files[] | "- " + .path + " (+" + (.additions | tostring) + "/-" + (.deletions | tostring) + ")")
     else dim("- none") end)
  ] | .[]
' "$detail_file" | fold -s -w "$wrap_width"
