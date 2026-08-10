#!/usr/bin/env bash

set -euo pipefail

lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$lib_dir/config.sh"
source "$lib_dir/views.sh"
source "$lib_dir/render.sh"
source "$lib_dir/picker.sh"

view="${1:-}"
command="${2:-}"
shift 2 || true

case "$command" in
  list)
    json=0
    for argument in "$@"; do
      case "$argument" in
        --json) json=1 ;;
        -h|--help|help) printf 'Usage: jira %s list [--json]\n' "$view"; exit 0 ;;
        *) echo "Unknown jira $view list argument: $argument" >&2; exit 1 ;;
      esac
    done
    if (( json )); then
      view_items_json "$view"
    else
      require_jira_base_url
      view_items_json "$view" | render_issue_rows | while IFS=$'\t' read -r display _; do printf '%s\n' "$display"; done
    fi
    ;;
  picker)
    [[ $# -eq 0 ]] || { echo "jira $view picker takes no arguments" >&2; exit 1; }
    open_picker "$view"
    ;;
  status)
    [[ $# -eq 0 ]] || { echo "jira $view status takes no arguments" >&2; exit 1; }
    exec bash "$lib_dir/status.sh" "$view"
    ;;
  *)
    echo "Usage: jira $view [list|picker]" >&2
    exit 1
    ;;
esac
