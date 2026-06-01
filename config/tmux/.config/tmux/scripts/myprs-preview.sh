#!/usr/bin/env bash

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
    " " + dim("repo:   ") + ($p.repository.nameWithOwner // ""),
    " " + dim("author: ") + ($p.author.name // $p.author.login) + " (" + $p.author.login + ")",
    " " + dim("status: ") + (if $p.isDraft then yellow("DRAFT") else green("READY") end),
    " " + dim("url:    ") + $p.url,
    " " + dim("review: ") + ($p.reviewDecision // "PENDING"),
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
