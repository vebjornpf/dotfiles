#!/usr/bin/env bash

set -euo pipefail

lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$lib_dir/config.sh"
source "$lib_dir/views.sh"
source "$lib_dir/render.sh"

view="${1:-}"
[[ -n "$view" ]] || exit 1
view_items_json "$view" | render_issue_rows
