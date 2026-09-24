#!/usr/bin/env bash

set -euo pipefail

repo="${1:-}"
number="${2:-}"

if [[ -z "$repo" || -z "$number" ]]; then
  echo "Usage: detail.sh <repo> <number>" >&2
  exit 1
fi

gh pr view "$number" --repo "$repo" \
  --json number,title,body,author,labels,assignees,reviewRequests,reviews,latestReviews,reviewDecision,statusCheckRollup,commits,files,additions,deletions,changedFiles,mergeable,mergeStateStatus,isDraft,headRefName,headRefOid,baseRefName,baseRefOid,createdAt,updatedAt,url \
  | jq --arg repo "$repo" '. + {repository: $repo}'
