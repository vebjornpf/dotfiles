#!/usr/bin/env bash
set -euo pipefail

gh api --paginate --slurp "orgs/$1/teams?per_page=100" |
  jq -r '[.[][]] | sort_by(.name | ascii_downcase)[] | [.slug, .name] | @tsv'
