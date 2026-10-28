#!/usr/bin/env zsh

set -e
root=${0:A:h:h}
compdef() { :; }
source "$root/config/zsh/.config/zsh/worktree.zsh"

test_dir=$(mktemp -d "${TMPDIR:-/tmp/opencode}/worktree-tabs.XXXXXX")
trap 'rm -rf -- "$test_dir"' EXIT

herdr() {
  print -r -- "$*" >> "$test_dir/calls"
  case "$1 $2" in
    'worktree list')
      if [[ -e $test_dir/open ]]; then
        print -r -- '{"result":{"worktrees":[{"path":"/worktrees/repo/feature","open_workspace_id":"w1"}]}}'
      else
        print -r -- '{"result":{"worktrees":[{"path":"/worktrees/repo/feature","open_workspace_id":null}]}}'
      fi
      ;;
    'worktree open'|'worktree create') touch "$test_dir/open" ;;
    'tab list') print -r -- '{"result":{"tabs":[{"tab_id":"w1:t1"}]}}' ;;
  esac
}

git() {
  [[ $* == *'rev-parse --path-format=absolute --git-common-dir' ]] || return 1
  print -r -- '/repos/repo/.git'
}

_wt_herdr_workspace /repos/repo /worktrees/repo/feature feature open
calls=$(<"$test_dir/calls")
[[ $calls == *'tab rename w1:t1 repo-wt'* ]] || { print -u2 'missing worktree tab rename'; exit 1; }
[[ $calls == *'tab create --workspace w1 --cwd /worktrees/repo/feature --label editor --no-focus'* ]] || exit 1
[[ $calls == *'tab create --workspace w1 --cwd /worktrees/repo/feature --label run --no-focus'* ]] || exit 1

: > "$test_dir/calls"
_wt_herdr_workspace /repos/repo /worktrees/repo/feature feature open
calls=$(<"$test_dir/calls")
[[ $calls != *'tab '* ]] || { print -u2 'reopening modified existing tabs'; exit 1; }

rm "$test_dir/open"
: > "$test_dir/calls"
_wt_herdr_workspace /repos/repo /worktrees/repo/feature feature create main feature
calls=$(<"$test_dir/calls")
[[ $calls == *'worktree create --cwd /repos/repo --base main --branch feature'* ]] || exit 1
[[ $calls == *'tab rename w1:t1 repo-wt'* ]] || exit 1
print 'PASS: worktree tabs are set up only for new workspaces'
