#!/usr/bin/env bash

set -euo pipefail

lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$lib_dir/common.sh"

repo_slug="${1:-}"

[[ -n "$repo_slug" ]] || exit 0

ensure_repo_clone "$repo_slug" >/dev/null 2>&1
