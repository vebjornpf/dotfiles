#!/usr/bin/env bash

set -euo pipefail

snapshot_file="$HOME/git/daily/jira/mywork-current.json"

if [[ ! -f "$snapshot_file" ]]; then
  exit 0
fi

jq -r '
  .[]
  | [
      ((.key // "") + "  " + (.fields.status.name // "") + "  " + (.fields.issuetype.name // "") + "  " + (.fields.priority.name // "") + "  " + (.fields.summary // "")),
      (.key // ""),
      (.fields.status.name // ""),
      (.fields.issuetype.name // ""),
      ("https://elhub.atlassian.net/browse/" + (.key // "")),
      (. | @base64)
    ]
  | @tsv
' "$snapshot_file"
