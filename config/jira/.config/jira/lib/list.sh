#!/usr/bin/env bash

set -euo pipefail

lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$lib_dir/env.sh"

target="${1:-mywork}"
state_dir="${JIRA_STATE_DIR:-$HOME/git/daily/jira}"

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

case "$target" in
  mywork)
    snapshot_file="$state_dir/mywork-current.json"
    [[ -f "$snapshot_file" ]] || exit 0
    jq '.items' "$snapshot_file" | render_rows
    ;;
  backlog)
    snapshot_file="$state_dir/all-current.json"
    [[ -f "$snapshot_file" ]] || exit 0
    jq '[.items[]? | select((.fields.status.name // "") == "Backlog")]' "$snapshot_file" | render_rows
    ;;
  epics)
    snapshot_file="$state_dir/all-current.json"
    [[ -f "$snapshot_file" ]] || exit 0
    jq '[.items[]? | select((.fields.issuetype.name // "") == "Epic")]' "$snapshot_file" | render_rows
    ;;
  all)
    all_file="$state_dir/all-current.json"
    mywork_file="$state_dir/mywork-current.json"
    source_files=()
    [[ -f "$all_file" ]] && source_files+=("$all_file")
    [[ -f "$mywork_file" ]] && source_files+=("$mywork_file")
    (( ${#source_files[@]} > 0 )) || exit 0
    jq -s '[.[].items[]?]' "${source_files[@]}" | render_rows
    ;;
  *)
    echo "Unsupported jira list target: $target" >&2
    exit 1
    ;;
esac
