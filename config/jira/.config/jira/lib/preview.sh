#!/usr/bin/env bash

set -euo pipefail

lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
key="${1:-}"

[[ -n "$key" ]] || exit 0
bash "$lib_dir/item.sh" "$key" --json | jq -r '
  ([.fields.description? // empty | .. | objects | .text? // empty] | join("\n")) as $description
  | "Key: \(.key // "")\nSummary: \(.fields.summary // "")\nDescription: \($description // "")\nStatus: \(.fields.status.name // "")\nAssignee: \(.fields.assignee.displayName // .fields.assignee.accountId // "Unassigned")\nReporter: \(.fields.reporter.displayName // .fields.reporter.accountId // "Unknown")\nPriority: \(.fields.priority.name // "")\nType: \(.fields.issuetype.name // "")"
'
