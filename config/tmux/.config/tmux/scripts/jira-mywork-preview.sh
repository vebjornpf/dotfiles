#!/usr/bin/env bash

set -euo pipefail

status_file="$HOME/git/daily/jira/sync-status.json"
target="${1:-mywork}"
b64="${2:-}"

last_sync="Never"

if [[ -f "$status_file" ]]; then
  synced_at="$(jq -r --arg target "$target" '.targets[$target].last_sync_at // .last_sync_at // empty' "$status_file")"
  [[ -n "$synced_at" ]] && last_sync="$synced_at"
fi

if [[ -z "$b64" ]]; then
  printf 'last sync %s\n' "$last_sync"
  exit 0
fi

printf '%s' "$b64" | base64 --decode | jq -r --arg last_sync "$last_sync" '
  def textify:
    if type == "string" then .
    elif type == "array" then map(textify) | join("")
    elif type == "object" then
      if has("text") then .text
      elif has("content") then (.content | textify)
      else ""
      end
    else ""
    end;

  . as $issue |
  [
    "last sync " + $last_sync,
    "",
    ($issue.key + " " + ($issue.fields.summary // "")),
    "",
    "status    " + ($issue.fields.status.name // ""),
    "type      " + ($issue.fields.issuetype.name // ""),
    "priority  " + ($issue.fields.priority.name // ""),
    "assignee  " + ($issue.fields.assignee.displayName // "Unassigned"),
    "reporter  " + ($issue.fields.reporter.displayName // "Unknown"),
    "url       https://elhub.atlassian.net/browse/" + $issue.key,
    (
      if ($issue.fields.description? // null) == null then
        ""
      else
        "\nDescription\n" + (($issue.fields.description.content // []) | textify)
      end
    )
  ]
  | .[]
'
