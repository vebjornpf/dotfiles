#!/usr/bin/env bash

set -euo pipefail

lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$lib_dir/env.sh"

require_jira_project_key

output="$JIRA_STATE_DIR/components.tsv"

echo "Fetching components for project $JIRA_PROJECT_KEY..." >&2

acli jira project view --key "$JIRA_PROJECT_KEY" --json \
  | jq -r '.components[]?.name // empty' \
  | LC_ALL=C sort -fu \
  | sed 's/^auth-consent-manager$/auth-grant-manager/' \
  > "$output"

count="$(wc -l < "$output" | tr -d ' ')"
echo "Wrote $count components to $output" >&2
