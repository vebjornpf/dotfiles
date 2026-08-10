#!/usr/bin/env bash

set -euo pipefail

render_issue_rows() {
  jq -r --arg base_url "${JIRA_BASE_URL%/}" '
    .[]
    | [
        ((.key // "") + "  " + (.fields.status.name // "") + "  " + ((.fields.assignee.displayName // .fields.assignee.display_name // .fields.assignee.accountId) // "Unassigned") + "  " + (.fields.issuetype.name // "") + "  " + (.fields.priority.name // "") + "  " + (.fields.summary // "")),
        (.key // ""),
        (.fields.status.name // ""),
        ($base_url + "/browse/" + (.key // "")),
        (. | @base64)
      ]
    | @tsv
  '
}

render_issue_summary() {
  jq -r '"\(.key // "")  \(.fields.status.name // "")  \(.fields.summary // "")"'
}
