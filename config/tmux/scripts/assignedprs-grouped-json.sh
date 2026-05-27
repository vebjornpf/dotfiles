#!/usr/bin/env bash

set -euo pipefail

{
  gh search prs --review-requested=@me --state=open \
    --limit 100 \
    --sort updated \
    --json author,commentsCount,createdAt,isDraft,isLocked,number,repository,state,title,updatedAt,url
  gh search prs --reviewed-by=@me --state=open \
    --limit 100 \
    --sort updated \
    --json author,commentsCount,createdAt,isDraft,isLocked,number,repository,state,title,updatedAt,url
} |
  jq -s '
    add
    | unique_by(.repository.nameWithOwner + "#" + .url)
    | sort_by(.repository.nameWithOwner)
    | group_by(.repository.nameWithOwner)
    | map({
        key: .[0].repository.nameWithOwner,
        value: {
          count: length,
        prs: map({
          url,
          number,
          title,
          author: .author.login,
          updatedAt
        })
      }
      })
    | from_entries
  '
