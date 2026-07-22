#!/usr/bin/env bash

set -euo pipefail

lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$lib_dir/common.sh"

url="${1:-}"

[[ -n "$url" ]] || exit 0

open_url "$url"
