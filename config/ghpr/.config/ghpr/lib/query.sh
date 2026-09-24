#!/usr/bin/env bash

set -euo pipefail

target="${1:-mine}"
username="${2:-}"
limit="${GHPR_LIMIT:-100}"

require_org() {
  if [[ -z "${GHPR_ORG:-}" ]]; then
    echo 'GHPR_ORG is required for cross-repository queries.' >&2
    echo 'Set it in ~/.config/local/tools.zsh, for example: GHPR_ORG="elhub"' >&2
    return 1
  fi
}

render_search_results() {
  jq -r '
    sort_by(.updatedAt) | reverse | .[] |
    [
      (.number | tostring),
      .repository.nameWithOwner,
      (.author.login // "unknown"),
      (.updatedAt // ""),
      (if .isDraft then "draft" else "open" end),
      (.title | gsub("[\\t\\r\\n]+"; " ")),
      .url
    ] | @tsv
  '
}

case "$target" in
  mine)
    require_org
    gh search prs "org:$GHPR_ORG" --author '@me' --state open --sort updated --order desc --limit "$limit" \
      --json number,title,repository,author,url,isDraft,updatedAt \
      | render_search_results
    ;;
  this)
    repo="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)" || {
      echo "ghpr this must run inside a GitHub repository." >&2
      exit 1
    }
    gh pr list --repo "$repo" --state open --limit "$limit" \
      --json number,title,author,url,isDraft,updatedAt \
      | jq -r --arg repo "$repo" '
          sort_by(.updatedAt) | reverse | .[] |
          [
            (.number | tostring),
            $repo,
            (.author.login // "unknown"),
            (.updatedAt // ""),
            (if .isDraft then "draft" else "open" end),
            (.title | gsub("[\\t\\r\\n]+"; " ")),
            .url
          ] | @tsv
        '
    ;;
  team)
    require_org
    team_query="org:$GHPR_ORG"
    if [[ -n "${GHPR_TEAM_REVIEW_EXCLUDE:-}" ]]; then
      if [[ ! "$GHPR_TEAM_REVIEW_EXCLUDE" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
        echo 'GHPR_TEAM_REVIEW_EXCLUDE must be an organization/team slug.' >&2
        exit 1
      fi
      team_query+=" -team-review-requested:$GHPR_TEAM_REVIEW_EXCLUDE"
    fi
    gh search prs "$team_query" --review-requested '@me' --state open --sort updated --order desc --limit "$limit" \
      --json number,title,repository,author,url,isDraft,updatedAt \
      | render_search_results
    ;;
  user)
    if [[ -z "$username" ]]; then
      echo "query.sh: username is required for target 'user'." >&2
      exit 1
    fi
    require_org
    gh search prs "org:$GHPR_ORG" --author "$username" --state open --sort updated --order desc --limit "$limit" \
      --json number,title,repository,author,url,isDraft,updatedAt \
      | render_search_results
    ;;
  *)
    echo "query.sh: unknown target '$target'." >&2
    exit 1
    ;;
esac
