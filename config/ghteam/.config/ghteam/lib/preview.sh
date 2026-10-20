#!/usr/bin/env bash
set -euo pipefail

org="$1"
slug="$2"
session="$3"
cache="$session/$slug.members"

if [[ ! -f "$cache" ]]; then
  # GraphQL includes profile names, avoiding a separate request per member.
  if ! gh api graphql --paginate --slurp -F org="$org" -F slug="$slug" -f query='
    query($org: String!, $slug: String!, $endCursor: String) {
      organization(login: $org) {
        team(slug: $slug) {
          members(first: 100, after: $endCursor) {
            nodes { name login }
            pageInfo { hasNextPage endCursor }
          }
        }
      }
    }' >"$cache.json"; then
    echo 'Unable to load members. Check gh authentication and organization access.'
    exit 1
  fi

  if ! jq -er '
    if any(.[]; .data.organization.team == null) then
      error("Team is not accessible")
    else
      [.[].data.organization.team.members.nodes[]]
      | unique_by(.login)
      | sort_by((if (.name // "") == "" then .login else .name end) | ascii_downcase)
      | if length == 0 then "No visible members."
        else map(if (.name // "") == "" then "@" + .login
                 else .name + " (@" + .login + ")" end) | join("\n")
        end
    end
  ' "$cache.json" >"$cache.pending"; then
    echo 'Unable to read team members.'
    exit 1
  fi
  mv "$cache.pending" "$cache"
fi

cat "$cache"
