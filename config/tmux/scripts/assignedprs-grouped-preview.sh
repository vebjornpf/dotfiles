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
    [
      "\u001b[1m" + $repo.repoName + "\u001b[0m",
      "\u001b[2m" + (($repo.count | tostring) + " open PRs") + "\u001b[0m",
      "\u001b[2m" + $clone + "\u001b[0m",
      "",
      ($repo.prs[]
        | "\u001b[1m#" + (.number | tostring) + "\u001b[0m"
          + "  " + .title
          + "\n"
          + "\u001b[2mauthor\u001b[0m   " + .author
          + "\n"
          + "\u001b[2mupdated\u001b[0m  " + (.updatedAt | sub("T"; " ") | sub("Z$"; ""))
          + "\n"
          + "\u001b[2murl\u001b[0m      " + (.url // "")
          + "\n"
      )
    ]
    | .[]
  ' |
  fold -s -w "$wrap_width"
