#!/usr/bin/env bash

set -euo pipefail

lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$lib_dir/env.sh"

component_name="${1:-}"

if [[ -z "$component_name" ]]; then
  echo "Usage: component-list.sh <component-name>" >&2
  exit 1
fi

require_jira_project_key
require_jira_base_url

render_rows() {
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
  '
}

component_jql_value="$(jq -rn --arg value "$component_name" '$value')"
query="project = $JIRA_PROJECT_KEY AND component = $component_jql_value AND statusCategory != Done ORDER BY updated DESC"

acli jira workitem search --jql "$query" --fields 'issuetype,key,assignee,reporter,priority,status,summary,description' --paginate --json | render_rows
