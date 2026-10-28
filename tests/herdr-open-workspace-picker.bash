#!/usr/bin/env bash

set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
source "$root/config/herdr/.config/herdr/lib/open-workspace-picker.bash"

test_dir=$(mktemp -d "${TMPDIR:-/tmp/opencode}/herdr-picker-test.XXXXXX")
trap 'rm -rf -- "$test_dir"' EXIT

herdr() {
  printf '%s\n' "$*" >> "$test_dir/calls"
  if [[ "$*" == 'workspace list' ]]; then
    if [[ ${fail:-} == list ]]; then
      printf 'list failed\n' >&2
      return 1
    fi
    printf '%s\n' "$fixture_workspaces"
  elif [[ ${fail:-} == "$2" ]]; then
    printf '%s failed\n' "$2" >&2
    return 1
  fi
}

check_close() {
  local name=$1 target=$2 expected_calls=$3 expected_header=$4 output calls
  : > "$test_dir/calls"
  output=$(open_workspace_picker_close "$target")
  calls=$(cat "$test_dir/calls")
  if [[ "$calls" != "$expected_calls" || "$output" != *"$expected_header"* ]]; then
    printf 'FAIL: %s\nCalls:\n%s\nHeader:\n%s\n' "$name" "$calls" "$output" >&2
    exit 1
  fi
  printf 'PASS: %s\n' "$name"
}

fixture_workspaces='{"result":{"workspaces":[{"workspace_id":"w1","label":"one","focused":true},{"workspace_id":"w2","label":"two","focused":false}]}}'
check_close 'active workspace switches before closing' w1 \
  $'workspace list\nworkspace focus w2\nworkspace close w1' 'enter: focus'
check_close 'background workspace does not change focus' w2 \
  $'workspace list\nworkspace close w2' 'enter: focus'
check_close 'stale selection is not closed' missing \
  'workspace list' 'Workspace is no longer open'

fail=focus
check_close 'focus failure prevents close' w1 \
  $'workspace list\nworkspace focus w2' 'Could not switch workspace: focus failed'
fail=close
check_close 'close failure stays visible' w2 \
  $'workspace list\nworkspace close w2' 'Could not close workspace: close failed'
fail=list
check_close 'list failure prevents mutations' w1 \
  'workspace list' 'Could not list workspaces: list failed'
unset fail

fixture_workspaces='{"result":{"workspaces":[{"workspace_id":"w2","label":"two","focused":true}]}}'
check_close 'last workspace stays open' w2 \
  'workspace list' 'Keeping the last workspace open'

fixture_workspaces='{"result":{"workspaces":[{"workspace_id":"w1","label":"one","focused":false},{"workspace_id":"w2","label":"two","focused":true}]}}'
check_close 'focus is read fresh rather than inherited from popup' w2 \
  $'workspace list\nworkspace focus w1\nworkspace close w2' 'enter: focus'

fzf() { return "${fzf_status:-130}"; }
fzf_status=130
open_workspace_picker
printf 'PASS: picker cancellation exits cleanly\n'
fzf_status=2
if open_workspace_picker; then
  printf 'FAIL: fzf errors must not be hidden\n' >&2
  exit 1
else
  [[ $? -eq 2 ]]
fi
printf 'PASS: picker errors are preserved\n'
