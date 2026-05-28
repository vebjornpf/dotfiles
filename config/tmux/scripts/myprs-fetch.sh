#!/usr/bin/env bash

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Fetch list of my open PRs
gh search prs --author "@me" --state open --limit 100 \
  --json number,repository \
  | jq -r '.[] | "\(.number)\t\(.repository.nameWithOwner)"' \
  | while IFS=$'\t' read -r number repo; do
    gh pr view "$number" --repo "$repo" \
      --json number,title,author,body,commits,reviews,statusCheckRollup,files,url,isDraft,createdAt,updatedAt \
      2>/dev/null \
      | jq --arg repo "$repo" '. + {repository: {nameWithOwner: $repo}}' \
      > "$tmpdir/${repo//\//_}_${number}.json"
  done

# Combine all results and format for fzf
jq -s '
  map(select(. != null and .number != null))
  | sort_by(.updatedAt)
  | reverse
  | .[]
  | "\(.number)\t\(.author.login)\t\(.title)\t\(.|@base64)"
' -r "$tmpdir"/*.json 2>/dev/null || true
