#!/usr/bin/env bash

set -euo pipefail

bash "$(dirname "$0")/assignedprs-grouped-json.sh" |
  jq -r '
    to_entries[]
    | {
        repoName: .key,
        count: .value.count,
        prs: .value.prs
      } as $repo
    | [
        $repo.repoName,
        ($repo.count | tostring),
        ($repo | @base64)
      ]
    | @tsv
  ' |
  awk -F '\t' '
    function trunc(s, n) {
      return length(s) > n ? substr(s, 1, n - 3) "..." : s
    }
    {
      repo = sprintf("%-32s", trunc($1, 32))
      count = sprintf("%3s", $2)
      display = repo "  " count " PRs"
      print display "\t" $1 "\t" $2 "\t" $3
    }
  '
