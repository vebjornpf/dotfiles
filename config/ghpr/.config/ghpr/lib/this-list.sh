#!/usr/bin/env bash

set -euo pipefail

if ! gh repo view --json nameWithOwner -q .nameWithOwner >/dev/null 2>&1; then
  echo "ghpr this must run inside a GitHub repo." >&2
  exit 1
fi

gh pr list --state open --limit 30 \
  --json number,title,author,commits,reviews,statusCheckRollup,files,url,isDraft,mergeable,mergeStateStatus,reviewDecision,headRefName,baseRefName \
  | jq -r '
      def na: "not_available";

      map({
        number: (.number | tostring),
        author: {
          login: (.author.login // na),
          name: (.author.name // na)
        },
        title: (.title // na),
        details: {
          url: (.url // na),
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
      })
      | .[]
      | [
          .number,
          .author.login,
          .title,
          (@base64)
        ]
      | @tsv
    '
