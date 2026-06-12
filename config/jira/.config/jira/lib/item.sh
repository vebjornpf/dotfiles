#!/usr/bin/env bash

set -euo pipefail

lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$lib_dir/env.sh"

key="${1:-}"
action="${2:-view}"
url=""

usage() {
  cat >&2 <<'EOF'
Usage: jira <scope> <KEY> [open|cp|cpk]
EOF
}

if [[ -z "$key" ]]; then
  usage
  exit 1
fi

case "$action" in
  view)
    acli jira workitem view "$key"
    ;;
  open)
    acli jira workitem view "$key" --web
    ;;
  cp)
    url="$(jira_browse_url "$key")"
    printf '%s' "$url" | xclip -selection clipboard
    ;;
  cpk)
    printf '%s' "$key" | xclip -selection clipboard
    ;;
  *)
    usage
    echo "Unsupported jira item action: $action" >&2
    exit 1
    ;;
esac
