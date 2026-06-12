#!/usr/bin/env bash

set -euo pipefail

lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$lib_dir/env.sh"

target="${1:-mywork}"
state_dir="${JIRA_STATE_DIR:-$HOME/git/daily/jira}"
snapshot_file="$state_dir/${target}-current.json"

require_jira_base_url

if [[ ! -f "$snapshot_file" ]]; then
  exit 0
fi

jq -r --arg base_url "${JIRA_BASE_URL%/}" '
  .[]
  | [
      ((.key // "") + "  " + (.fields.status.name // "") + "  " + (.fields.issuetype.name // "") + "  " + (.fields.priority.name // "") + "  " + (.fields.summary // "")),
      (.key // ""),
      (.fields.status.name // ""),
      (.fields.issuetype.name // ""),
      ($base_url + "/browse/" + (.key // "")),
      (. | @base64)
    ]
  | @tsv
' "$snapshot_file"
