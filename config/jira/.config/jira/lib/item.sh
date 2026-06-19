#!/usr/bin/env bash

set -euo pipefail

lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$lib_dir/env.sh"
source "$HOME/.config/zsh/lib/clipboard.sh"

key="${1:-}"
action="${2:-view}"
url=""

usage() {
  cat >&2 <<'EOF'
Usage: jira item <KEY> [open|cp|cpk]
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
    printf '%s' "$url" | clipboard_copy
    ;;
  cpk)
    printf '%s' "$key" | clipboard_copy
    ;;
  *)
    usage
    echo "Unsupported jira item action: $action" >&2
    exit 1
    ;;
esac
