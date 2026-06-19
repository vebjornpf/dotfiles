#!/usr/bin/env bash

set -euo pipefail

GHPR_HOME="${GHPR_HOME:-$HOME/.config/ghpr}"
repo="$1"
number="$2"
wrap_width="${FZF_PREVIEW_COLUMNS:-80}"

if [[ "$wrap_width" -lt 20 ]]; then
  wrap_width=80
fi

bash "$GHPR_HOME/lib/mine-item.sh" "$repo" "$number" | jq -r '
  def c(code; s): "\u001b[" + code + "m" + s + "\u001b[0m";
  def green(s): c("32"; s);
  def yellow(s): c("33"; s);
  def red(s): c("31"; s);
  def bold(s): c("1"; s);
  def dim(s): c("2"; s);
  def render_value(s): if s == "not_available" then red(s) else s end;

  . as $p |
  [
    " " + bold("#\($p.number) ") + $p.title,
    " " + dim("repo:   ") + render_value($p.repo),
    " " + dim("author: ") + render_value($p.details.author.name) + " (" + render_value($p.details.author.login) + ")",
    " " + dim("status: ") + (if $p.details.state.is_draft then yellow("DRAFT") else green("READY") end),
    " " + dim("url:    ") + render_value($p.details.url),
    " " + dim("review: ") + render_value($p.details.state.review_decision),
    " " + dim("merge:  ") + render_value($p.details.state.mergeable) + "/" + render_value($p.details.state.merge_state_status),
    " " + dim("branch: ") + render_value($p.details.branches.head) + " -> " + render_value($p.details.branches.base),
    "",
    "Status checks:",
    (if ($p.details.checks|length)>0 then
       ($p.details.checks[]
        | "- " + .context + ": " +
          (if .state=="SUCCESS" then green(.state)
           elif .state=="PENDING" then yellow(.state)
           elif .state=="not_available" then red(.state)
           else red(.state) end) +
          (if .target_url != "not_available" then
              "\n" + .target_url
           else "" end))
     else "- none" end),
    "",
    "Commits:",
    ($p.details.commits | map("- " + (if .oid == "not_available" then red(.oid) else .oid[0:7] end) + " " + render_value(.headline)) | .[]),
    "",
    "Reviews:",
    (if ($p.details.reviews|length)>0 then
       ($p.details.reviews[]
        | "- " + render_value(.author_login) + ": " + render_value(.state) +
          (if .commit_oid != "not_available" then " @" + (.commit_oid[0:7]) else "" end))
     else "- none" end),
    "",
    "Files:",
    ($p.details.files | map("- " + render_value(.path) + " (+" + (.additions|tostring) + "/-" + (.deletions|tostring) + ")") | .[])
  ]
  | .[]
  ' | fold -s -w "$wrap_width"
