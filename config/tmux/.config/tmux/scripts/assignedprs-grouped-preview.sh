#!/usr/bin/env bash

set -euo pipefail

payload_b64="${1:-}"

if [[ -z "$payload_b64" ]]; then
  echo "Missing repo payload" >&2
  exit 1
fi

wrap_width="${FZF_PREVIEW_COLUMNS:-80}"
if [[ "$wrap_width" -lt 20 ]]; then
  wrap_width=80
fi

repo_json=$(printf '%s' "$payload_b64" | base64 --decode 2>/dev/null)
repo_short=$(printf '%s' "$repo_json" | jq -r '.repoName | split("/")[1]')
clone_path="$HOME/git/$repo_short"
if [[ -d "$clone_path" ]]; then
  clone_status="cloned   $clone_path"
else
  clone_status="not cloned"
fi

printf '%s' "$repo_json" |
  jq -r --arg clone "$clone_status" '
    . as $repo |
    ($repo.prs | map(select(.change == "NEW")) | length) as $newCount |
    ($repo.prs | map(select(.change == "UPDATED")) | length) as $updatedCount |
    (($repo.removedPrs // []) | length) as $removedCount |
    [
      "\u001b[1m" + $repo.repoName + "\u001b[0m",
      "\u001b[2m" + (($repo.count | tostring) + " open PRs") + "\u001b[0m",
      "\u001b[2m" + $clone + "\u001b[0m",
      (if ($repo.summary // "") != "" then "\u001b[33mchanges since last fetch\u001b[0m  " + $repo.summary else empty end),
      (if $newCount > 0 or $updatedCount > 0 or $removedCount > 0 then
         "\u001b[2mcounts\u001b[0m   new: " + ($newCount | tostring) + ", updated: " + ($updatedCount | tostring) + ", removed: " + ($removedCount | tostring)
       else empty end),
      "",
      ($repo.prs[]
        | (if (.change // "") == "NEW" then "\u001b[32m[NEW]\u001b[0m "
           elif (.change // "") == "UPDATED" then "\u001b[33m[UPDATED]\u001b[0m "
           else "" end)
          + "\u001b[1m#" + (.number | tostring) + "\u001b[0m"
          + "  " + .title
          + "\n"
          + "\u001b[2mauthor\u001b[0m   " + .author
          + (if (.changeDetail // "") != "" then "\n\u001b[2mchange\u001b[0m   " + .changeDetail else "" end)
          + "\n"
          + "\u001b[2mupdated\u001b[0m  " + (.updatedAt | sub("T"; " ") | sub("Z$"; ""))
          + "\n"
          + "\u001b[2murl\u001b[0m      " + (.url // "")
          + "\n"
      ),
      (if $removedCount > 0 then
         "Removed since last fetch:"
       else empty end),
      (if $removedCount > 0 then
         ($repo.removedPrs[]
           | "\u001b[31m[REMOVED]\u001b[0m \u001b[1m#" + (.number | tostring) + "\u001b[0m"
             + "  " + .title
             + "\n"
             + "\u001b[2mauthor\u001b[0m   " + .author
             + "\n"
             + "\u001b[2mupdated\u001b[0m  " + (.updatedAt | sub("T"; " ") | sub("Z$"; ""))
             + "\n"
             + "\u001b[2murl\u001b[0m      " + (.url // "")
             + "\n"
         )
       else empty end)
    ]
    | .[]
  ' |
  fold -s -w "$wrap_width"
