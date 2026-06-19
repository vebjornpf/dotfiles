#!/usr/bin/env bash

set -euo pipefail

GHPR_HOME="${GHPR_HOME:-$HOME/.config/ghpr}"
source "$GHPR_HOME/lib/common.sh"

ensure_ghpr_state_dir

state_file="$(mine_state_file)"
tmpfile="$(mktemp)"
trap 'rm -f "${tmpfile:-}"' EXIT

prs_json="$({
  gh search prs --author "@me" --state open --limit 100 \
    --json number,repository \
    | jq -r '.[] | [.number, .repository.nameWithOwner] | @tsv' \
    | while IFS=$'\t' read -r number repo; do
        gh pr view "$number" --repo "$repo" \
          --json number,title,author,body,commits,reviews,statusCheckRollup,files,url,isDraft,createdAt,updatedAt,mergeable,mergeStateStatus,reviewDecision,headRefName,baseRefName \
          2>/dev/null \
          | jq --arg repo "$repo" '
              def na: "not_available";

              {
                repo: $repo,
                number: (.number | tostring),
                title: (.title // na),
                details: {
                  url: (.url // na),
                  author: {
                    login: (.author.login // na),
                    name: (.author.name // na)
                  },
                  state: {
                    is_draft: (.isDraft // false),
                    review_decision: (.reviewDecision // na),
                    mergeable: (.mergeable // na),
                    merge_state_status: (.mergeStateStatus // na)
                  },
                  branches: {
                    head: (.headRefName // na),
                    base: (.baseRefName // na)
                  },
                  timestamps: {
                    created_at: (.createdAt // na),
                    updated_at: (.updatedAt // na)
                  },
                  checks: ((.statusCheckRollup // []) | map({
                    context: (.context // na),
                    state: (.state // na),
                    target_url: (.targetUrl // na)
                  })),
                  commits: ((.commits // []) | map({
                    oid: (.oid // na),
                    headline: (.messageHeadline // na)
                  })),
                  reviews: ((.reviews // []) | map({
                    author_login: (.author.login // na),
                    state: (.state // na),
                    commit_oid: (.commit.oid // na)
                  })),
                  files: ((.files // []) | map({
                    path: (.path // na),
                    additions: (.additions // 0),
                    deletions: (.deletions // 0),
                    change_type: (.changeType // na)
                  }))
                }
              }
            '
      done \
    | jq -s 'map(select(. != null and .number != null)) | sort_by(.details.timestamps.updated_at) | reverse'
} )"

jq -n --arg last_synced_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --argjson prs "$prs_json" '{last_synced_at: $last_synced_at, prs: $prs}' >"$tmpfile"

mv "$tmpfile" "$state_file"
