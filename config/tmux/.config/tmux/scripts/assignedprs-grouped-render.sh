#!/usr/bin/env bash

set -euo pipefail

current_file="${1:-}"
previous_file="${2:-}"

if [[ -z "$current_file" ]]; then
  echo "Usage: assignedprs-grouped-render.sh <current-json> [previous-json]" >&2
  exit 1
fi

if [[ ! -f "$current_file" ]]; then
  echo "Missing snapshot file: $current_file" >&2
  exit 1
fi

compare=false
previous_input="$current_file"
if [[ -n "$previous_file" && -f "$previous_file" ]]; then
  compare=true
  previous_input="$previous_file"
fi

jq -nr \
  --argjson compare "$compare" \
  --slurpfile current "$current_file" \
  --slurpfile previous "$previous_input" '
    def pr_map: map({ key: (.number | tostring), value: . }) | from_entries;

    ($current[0]) as $currentSnapshot
    | (if $compare then ($previous[0] // {}) else {} end) as $previousSnapshot
    | $currentSnapshot
    | to_entries[]
    | .key as $repoName
    | .value as $repo
    | ($previousSnapshot[$repoName] // null) as $prevRepo
    | (($prevRepo.prs // []) | pr_map) as $prevPrs
    | ($repo.prs | map(
        (.number | tostring) as $prKey
        | ($prevPrs[$prKey] // null) as $prevPr
        | . + {
            change: (
              if ($compare | not) then ""
              elif $prevRepo == null then "NEW"
              elif $prevPr == null then "NEW"
              elif ($prevPr.title // "") != (.title // "") then "UPDATED"
              elif ($prevPr.updatedAt // "") != (.updatedAt // "") then "UPDATED"
              else ""
              end
            ),
            changeDetail: (
              if ($compare | not) then ""
              elif $prevRepo == null or $prevPr == null then "new pr"
              else [
                if ($prevPr.title // "") != (.title // "") then "title" else empty end,
                if ($prevPr.updatedAt // "") != (.updatedAt // "") then "activity" else empty end
              ] | join(", ")
              end
            )
          }
      )) as $prsWithChange
    | (($repo.prs | pr_map) // {}) as $currentPrs
    | ($prsWithChange | map(select(.change == "NEW")) | length) as $newCount
    | ($prsWithChange | map(select(.change == "UPDATED")) | length) as $updatedCount
    | (($prevRepo.prs // []) | map(select(($currentPrs[(.number | tostring)] // null) == null) | . + { change: "REMOVED", changeDetail: "removed pr" })) as $removedPrs
    | ($removedPrs | length) as $removedCount
    | {
        repoName: $repoName,
        count: $repo.count,
        prs: $prsWithChange,
        removedPrs: $removedPrs,
        status: (
          if ($compare | not) then ""
          elif $prevRepo == null then "NEW"
          elif $newCount > 0 or $updatedCount > 0 or $removedCount > 0 or (($prevRepo.count // 0) != $repo.count) then "UPDATED"
          else ""
          end
        ),
        newCount: $newCount,
        updatedCount: $updatedCount,
        removedCount: $removedCount,
        summary: (
          if ($compare | not) then ""
          elif $prevRepo == null then "NEW repo"
          else [
            if $newCount > 0 then "+" + ($newCount | tostring) + " new" else empty end,
            if $updatedCount > 0 then "~" + ($updatedCount | tostring) + " updated" else empty end,
            if $removedCount > 0 then "-" + ($removedCount | tostring) + " removed" else empty end
          ] | join(", ")
          end
        )
      }
    | [
        .repoName,
        (.count | tostring),
        .summary,
        (. | @base64)
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
      summary = $3
      if (summary != "") {
        summary = "  " summary
      }
      display = repo "  " count " PRs" summary
      print display "\t" $1 "\t" $2 "\t" $4
    }
  '
