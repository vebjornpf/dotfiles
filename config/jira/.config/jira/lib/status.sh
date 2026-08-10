#!/usr/bin/env bash

set -euo pipefail

lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$lib_dir/views.sh"
source "$lib_dir/status-render.sh"

view="${1:-}"
[[ -n "$view" ]] || { echo 'Usage: status.sh <team|me>' >&2; exit 1; }

render_status_items "$(view_items_json "$view")"
