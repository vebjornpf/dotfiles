# Change directory to a workspace using native zsh completion.
wcd() {
  if (( $# > 1 )); then
    print -u2 'Usage: wcd [workspace]'
    return 1
  fi

  if (( $# == 1 )); then
    builtin cd -- "$1"
    return
  fi

  print -u2 'Usage: wcd <Tab> to select a workspace'
  return 1
}

_wcd_candidates() {
  local root
  local -a roots
  roots=(${(s.:.)WCD_PATHS:-$HOME/git:$HOME/projects:$HOME/work})

  for root in "${roots[@]}"; do
    [[ -d "$root" ]] || continue
    print -rl -- "$root"/*(N/)
  done

  if git rev-parse --show-toplevel >/dev/null 2>&1; then
    git worktree list --porcelain | awk '/^worktree / { sub(/^worktree /, ""); print }'
  fi
}

_wcd() {
  local -a candidates
  candidates=(${(f)"$(_wcd_candidates)"})
  _describe 'workspace' candidates
}

compdef _wcd wcd
