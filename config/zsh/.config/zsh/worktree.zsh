# List Herdr-managed worktrees and their Git status.
_wt_list() {
  local root="$HOME/.herdr/worktrees"
  local checkout branch state
  local -a repos branches states checkouts
  local -i repo_width=4 branch_width=6 status_width=6 i

  for checkout in "$root"/*/*(N/); do
    [[ $(git -C "$checkout" rev-parse --show-toplevel 2>/dev/null) == "$checkout" ]] || continue

    branch=$(git -C "$checkout" branch --show-current) || return
    [[ -n $branch ]] || branch="$(git -C "$checkout" rev-parse --short HEAD) (detached)"
    state=clean
    [[ -z $(git -C "$checkout" status --porcelain) ]] || state=modified

    repos+=("${checkout:h:t}")
    branches+=("$branch")
    states+=("$state")
    checkouts+=("$checkout")
    (( ${#repos[-1]} > repo_width )) && repo_width=${#repos[-1]}
    (( ${#branch} > branch_width )) && branch_width=${#branch}
    (( ${#state} > status_width )) && status_width=${#state}
  done

  printf '%-*s  %-*s  %-*s  %s\n' $repo_width REPO $branch_width BRANCH $status_width STATUS PATH
  if (( ! ${#checkouts} )); then
    print -r -- 'No Herdr worktrees found.'
    return
  fi
  for (( i = 1; i <= ${#checkouts}; i++ )); do
    printf '%-*s  %-*s  %-*s  %s\n' $repo_width "$repos[i]" $branch_width "$branches[i]" \
      $status_width "$states[i]" "$checkouts[i]"
  done
}

_wt_create() {
  local name=$1
  local checkout base common_dir repo target

  if [[ $name == */* || $name == . || $name == .. ]] || ! git check-ref-format --branch "$name" >/dev/null 2>&1; then
    print -u2 'wt: name must be a valid branch and a single directory name'
    return 1
  fi

  checkout=$(git rev-parse --show-toplevel 2>/dev/null) || {
    print -u2 'wt: run create inside a Git checkout'
    return 1
  }
  base=$(git branch --show-current) || return
  if [[ -z $base ]]; then
    print -u2 'wt: cannot create from a detached HEAD'
    return 1
  fi

  common_dir=$(git rev-parse --path-format=absolute --git-common-dir) || return
  repo=${common_dir:h:t}
  target="$HOME/.herdr/worktrees/$repo/$name"

  if [[ -e $target || -L $target ]]; then
    print -u2 -- "wt: path already exists: $target"
    return 1
  fi
  if git show-ref --verify --quiet "refs/heads/$name"; then
    print -u2 -- "wt: branch already exists: $name"
    return 1
  fi

  mkdir -p -- "${target:h}" || return
  herdr worktree create --cwd "$checkout" --base "$base" --branch "$name" \
    --path "$target" --label "$name" --focus --trust-repository
}

_wt_pick() {
  local root="$HOME/.herdr/worktrees"
  local checkout selected
  local -a checkouts

  for checkout in "$root"/*/*(N/); do
    [[ $(git -C "$checkout" rev-parse --show-toplevel 2>/dev/null) == "$checkout" ]] || continue
    checkouts+=("$checkout")
  done

  if (( ! ${#checkouts} )); then
    print -u2 'wt: no Herdr worktrees found'
    return 1
  fi
  if ! command -v fzf >/dev/null; then
    print -u2 'wt: fzf is required to pick a worktree'
    return 1
  fi

  selected=$(printf '%s\n' "${checkouts[@]}" | fzf --prompt="$1") || return
  [[ -n $selected ]] || return 1
  print -r -- "$selected"
}

_wt_is_managed() {
  local root="$HOME/.herdr/worktrees"
  local checkout

  for checkout in "$root"/*/*(N/); do
    [[ $1 == "$checkout" && $(git -C "$checkout" rev-parse --show-toplevel 2>/dev/null) == "$checkout" ]] && return 0
  done
  return 1
}

_wt_cd() {
  local selected=$1
  local common_dir label name

  if [[ ${HERDR_ENV:-} != 1 ]]; then
    print -u2 'wt: run cd inside Herdr to open a worktree workspace'
    return 1
  fi

  if ! _wt_is_managed "$selected"; then
    print -u2 -- "wt: not a managed Herdr worktree: $selected"
    return 1
  fi
  common_dir=$(git -C "$selected" rev-parse --path-format=absolute --git-common-dir) || return
  name=${selected:t}
  label=$name
  if [[ $name == pr-<->-* ]]; then
    label=${name#pr-}
    label="#${label%%-*}"
  fi
  herdr worktree open --cwd "${common_dir:h}" --path "$selected" \
    --label "$label" --focus --trust-repository >/dev/null
}

_wt_remove() {
  local selected changes common_dir source workspace_id answer

  if [[ ${HERDR_ENV:-} != 1 ]]; then
    print -u2 'wt: run remove inside Herdr'
    return 1
  fi

  if (( $# )); then
    selected=$1
    if ! _wt_is_managed "$selected"; then
      print -u2 -- "wt: not a managed Herdr worktree: $selected"
      return 1
    fi
  else
    selected=$(_wt_pick 'Remove worktree> ') || return
  fi
  changes=$(git -C "$selected" status --porcelain) || return
  if [[ -n $changes ]]; then
    print -u2 -- "wt: worktree has uncommitted changes: $selected"
    return 1
  fi

  read -r "answer?Remove worktree $selected? [y/N] " || return
  [[ $answer == [yY] ]] || return 0

  common_dir=$(git -C "$selected" rev-parse --path-format=absolute --git-common-dir) || return
  source=${common_dir:h}
  workspace_id=$(herdr worktree list --cwd "$source" --trust-repository |
    jq -r --arg selected "$selected" '.result.worktrees[]? | select(.path == $selected) | .open_workspace_id // empty') || return

  if [[ -n $workspace_id ]]; then
    herdr worktree remove --workspace "$workspace_id" --trust-repository
  else
    git -C "$source" worktree remove -- "$selected"
  fi
}

wt() {
  case $1 in
    ''|list)
      if (( $# > 1 )); then
        print -u2 'Usage: wt [list | cd | create <name> | remove]'
        return 1
      fi
      _wt_list
      ;;
    cd)
      if (( $# != 2 )); then
        print -u2 'Usage: wt cd <worktree-path>'
        return 1
      fi
      _wt_cd "$2"
      ;;
    create)
      if (( $# != 2 )); then
        print -u2 'Usage: wt create <name>'
        return 1
      fi
      _wt_create "$2"
      ;;
    remove)
      if (( $# > 2 )); then
        print -u2 'Usage: wt remove [worktree-path]'
        return 1
      fi
      _wt_remove "${@:2}"
      ;;
    *)
      print -u2 'Usage: wt [list | cd | create <name> | remove]'
      return 1
      ;;
  esac
}

_wt() {
  case $CURRENT in
    2)
      local -a commands=(
        'list:show Herdr worktrees'
        'cd:open a Herdr worktree workspace'
        'create:create a worktree from the current branch'
        'remove:remove a clean Herdr worktree'
      )
      _describe 'wt command' commands
      ;;
    3)
      case ${words[2]} in
        create) _message 'new branch/worktree name' ;;
        cd|remove)
          local root="$HOME/.herdr/worktrees"
          local checkout branch state
          local -a worktrees
          for checkout in "$root"/*/*(N/); do
            [[ $(git -C "$checkout" rev-parse --show-toplevel 2>/dev/null) == "$checkout" ]] || continue
            branch=$(git -C "$checkout" branch --show-current) || continue
            [[ -n $branch ]] || branch=$(git -C "$checkout" rev-parse --short HEAD)
            state=clean
            [[ -z $(git -C "$checkout" status --porcelain) ]] || state=modified
            worktrees+=("$checkout:${checkout:h:t}  $branch  $state")
          done
          (( ${#worktrees} )) && _describe 'worktree' worktrees
          ;;
      esac
      ;;
  esac
}

compdef _wt wt
