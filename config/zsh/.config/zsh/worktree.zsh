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
  _wt_herdr_workspace "$checkout" "$target" "$name" create "$base" "$name"
}

_wt_create_from() {
  _wt_require_open || return
  local base=${1:-} name=${2:-}
  local source common_dir rows selected target

  source=$(git rev-parse --show-toplevel 2>/dev/null) || {
    print -u2 'wt: run create-from inside a Git checkout'
    return 1
  }
  if [[ -z $base ]]; then
    _wt_require_open fzf || return
    rows=$(_wt_branch_rows) || return
    if [[ -z $rows ]]; then
      print -u2 'wt: no branches found'
      return 1
    fi
    selected=$(print -r -- "$rows" | fzf --no-sort --delimiter=$'\t' --prompt='Base> ') || return
    [[ -n $selected ]] || return 1
    base=${selected#*$'\t'}
  fi
  if ! git rev-parse --verify --quiet "$base^{commit}" >/dev/null; then
    print -u2 -- "wt: base not found: $base"
    return 1
  fi
  if [[ -z $name ]]; then
    read -r "name?New branch from $base: " || return
  fi
  if [[ $name == */* || $name == . || $name == .. ]] || ! git check-ref-format --branch "$name" >/dev/null 2>&1; then
    print -u2 'wt: name must be a valid branch and a single directory name'
    return 1
  fi
  if git show-ref --verify --quiet "refs/heads/$name"; then
    print -u2 -- "wt: branch already exists: $name"
    return 1
  fi

  common_dir=$(git rev-parse --path-format=absolute --git-common-dir) || return
  target="$HOME/.herdr/worktrees/${common_dir:h:t}/$name"
  if [[ -e $target || -L $target ]]; then
    print -u2 -- "wt: path already exists: $target"
    return 1
  fi

  mkdir -p -- "${target:h}" || return
  git -C "$source" worktree add --no-track -b "$name" -- "$target" "$base" || return
  _wt_open_workspace "$source" "$target" "$name"
}

_wt_require_open() {
  local dependency
  if [[ ${HERDR_ENV:-} != 1 ]]; then
    print -u2 'wt: run branch and pr inside Herdr'
    return 1
  fi
  for dependency in git herdr "$@"; do
    if ! command -v "$dependency" >/dev/null 2>&1; then
      print -u2 -- "wt: $dependency is required"
      return 1
    fi
  done
}

# Find any existing checkout of a branch, including the main checkout.
_wt_branch_path() {
  local source=$1 branch=$2 field checkout
  while IFS= read -r -d '' field; do
    case $field in
      'worktree '*) checkout=${field#worktree } ;;
      "branch refs/heads/$branch") print -r -- "$checkout"; return ;;
    esac
  done < <(git -C "$source" worktree list --porcelain -z)
}

_wt_slug() {
  local slug
  slug=$(print -rn -- "$1" | LC_ALL=C tr -cs '[:alnum:].-' '-') || return
  slug=${slug##-}
  slug=${slug%%-}
  [[ -n $slug && $slug != . && $slug != .. ]] || slug=branch
  print -r -- "$slug"
}

_wt_herdr_workspace() {
  local source=$1 target=$2 label=$3 action=$4 base=${5:-} branch=${6:-}
  local before workspace_id tab_id common_dir repo

  if ! command -v jq >/dev/null 2>&1; then
    print -u2 'wt: jq is required to set up a Herdr worktree workspace'
    return 1
  fi

  before=$(herdr worktree list --cwd "$source" --trust-repository |
    jq -r --arg path "$target" '.result.worktrees[]? | select(.path == $path) | .open_workspace_id // empty') || return

  if [[ $action == create ]]; then
    herdr worktree create --cwd "$source" --base "$base" --branch "$branch" \
      --path "$target" --label "$label" --focus --trust-repository >/dev/null || return
  else
    herdr worktree open --cwd "$source" --path "$target" \
      --label "$label" --focus --trust-repository >/dev/null || return
  fi

  [[ -z $before ]] || return 0
  workspace_id=$(herdr worktree list --cwd "$source" --trust-repository |
    jq -r --arg path "$target" '.result.worktrees[]? | select(.path == $path) | .open_workspace_id // empty') || return
  [[ -n $workspace_id ]] || { print -u2 'wt: could not find new Herdr workspace'; return 1; }
  tab_id=$(herdr tab list --workspace "$workspace_id" | jq -r '.result.tabs[0].tab_id // empty') || return
  [[ -n $tab_id ]] || { print -u2 'wt: could not find initial Herdr tab'; return 1; }

  common_dir=$(git -C "$target" rev-parse --path-format=absolute --git-common-dir) || return
  repo=${common_dir:h:t}
  herdr tab rename "$tab_id" "$repo-wt" >/dev/null || return
  herdr tab create --workspace "$workspace_id" --cwd "$target" --label editor --no-focus >/dev/null || return
  herdr tab create --workspace "$workspace_id" --cwd "$target" --label run --no-focus >/dev/null
}

_wt_open_workspace() {
  local source=$1 target=$2 label=$3 source_common target_common
  source_common=$(git -C "$source" rev-parse --path-format=absolute --git-common-dir) || return
  target_common=$(git -C "$target" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || return
  if [[ $source_common != $target_common || $(git -C "$target" rev-parse --show-toplevel) != "$target" ]]; then
    print -u2 -- "wt: not a worktree of the current repository: $target"
    return 1
  fi
  _wt_herdr_workspace "$source" "$target" "$label" open
}

_wt_branch_rows() {
  local refs ref symbolic
  refs=$(git for-each-ref --sort=refname --format='%(refname)%09%(symref)' refs/heads refs/remotes) || return
  while IFS=$'\t' read -r ref symbolic; do
    [[ -n $ref && -z $symbolic ]] || continue
    case $ref in
      refs/heads/*) print -r -- $'local\t'"${ref#refs/heads/}" ;;
      refs/remotes/*) print -r -- $'remote\t'"${ref#refs/remotes/}" ;;
    esac
  done <<< "$refs"
}

_wt_branch() {
  _wt_require_open || return
  local source common_dir rows selected kind branch remote_ref target slug existing upstream
  source=$(git rev-parse --show-toplevel 2>/dev/null) || {
    print -u2 'wt: run branch inside a Git checkout'
    return 1
  }
  common_dir=$(git rev-parse --path-format=absolute --git-common-dir) || return
  if (( $# )); then
    branch=$1
    if git show-ref --verify --quiet "refs/heads/$branch"; then
      kind=local
    elif git show-ref --verify --quiet "refs/remotes/$branch" &&
        ! git symbolic-ref -q "refs/remotes/$branch" >/dev/null; then
      kind=remote
    else
      print -u2 -- "wt: branch not found: $branch"
      return 1
    fi
  else
    _wt_require_open fzf || return
    rows=$(_wt_branch_rows) || return
    if [[ -z $rows ]]; then
      print -u2 'wt: no branches found'
      return 1
    fi
    selected=$(print -r -- "$rows" | fzf --no-sort --delimiter=$'\t' --prompt='Branch> ') || return
    [[ -n $selected ]] || return 1
    kind=${selected%%$'\t'*}
    branch=${selected#*$'\t'}
  fi
  if [[ $kind == remote ]]; then
    remote_ref=$branch
    branch=${remote_ref#*/}
    if git show-ref --verify --quiet "refs/heads/$branch"; then
      upstream=$(git for-each-ref --format='%(upstream)' "refs/heads/$branch") || return
      if [[ $upstream != "refs/remotes/$remote_ref" ]]; then
        print -u2 -- "wt: local branch $branch already exists and does not track $remote_ref"
        return 1
      fi
    fi
  fi
  existing=$(_wt_branch_path "$source" "$branch") || return
  if [[ -n $existing ]]; then
    _wt_open_workspace "$source" "$existing" "$branch"
    return
  fi
  slug=$(_wt_slug "$branch") || return
  target="$HOME/.herdr/worktrees/${common_dir:h:t}/$slug"
  if [[ -e $target || -L $target ]]; then
    print -u2 -- "wt: path already exists: $target"
    return 1
  fi
  mkdir -p -- "${target:h}" || return
  if [[ $kind == remote ]] && ! git show-ref --verify --quiet "refs/heads/$branch"; then
    git -C "$source" worktree add --track -b "$branch" -- "$target" "$remote_ref" || return
  else
    git -C "$source" worktree add -- "$target" "$branch" || return
  fi
  _wt_open_workspace "$source" "$target" "$branch"
}

_wt_pr_rows() {
  local prs
  prs=$(gh pr list --state open --limit 200 --json number,title,author,headRefName) || return
  print -r -- "$prs" | jq -r '.[] | [.number, .headRefName, .title, .author.login] | @tsv'
}

_wt_pr() {
  _wt_require_open gh || return
  local source common_dir rows selected number head_branch branch slug target existing
  source=$(git rev-parse --show-toplevel 2>/dev/null) || {
    print -u2 'wt: run pr inside a Git checkout'
    return 1
  }
  common_dir=$(git rev-parse --path-format=absolute --git-common-dir) || return
  if (( $# )); then
    number=$1
    if [[ $number != <-> || $number == 0 ]]; then
      print -u2 'wt: PR number must be a positive integer'
      return 1
    fi
    head_branch=$(gh pr view "$number" --json headRefName --jq .headRefName) || return
  else
    _wt_require_open fzf jq || return
    rows=$(_wt_pr_rows) || return
    if [[ -z $rows ]]; then
      print -u2 'wt: no open pull requests found'
      return 1
    fi
    selected=$(print -r -- "$rows" | fzf --delimiter=$'\t' --with-nth=1,3,4,2 --prompt='PR> ') || return
    [[ -n $selected ]] || return 1
    number=${selected%%$'\t'*}
    head_branch=${${selected#*$'\t'}%%$'\t'*}
  fi
  branch="pr-$number"
  slug=$(_wt_slug "${(L)head_branch}") || return
  target="$HOME/.herdr/worktrees/${common_dir:h:t}/pr-$number-$slug"
  if [[ -e $target || -L $target ]]; then
    _wt_open_workspace "$source" "$target" "#$number"
    return
  fi
  existing=$(_wt_branch_path "$source" "$branch") || return
  if [[ -n $existing ]]; then
    _wt_open_workspace "$source" "$existing" "#$number"
    return
  fi
  mkdir -p -- "${target:h}" || return
  gh pr checkout "$number" --branch "$branch" --worktree "$target" || return
  _wt_open_workspace "$source" "$target" "#$number"
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
  _wt_herdr_workspace "${common_dir:h}" "$selected" "$label" open
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
        print -u2 'Usage: wt [list | branch | pr | cd <worktree-path> | create <name> | create-from [base] [name] | remove [worktree-path]]'
        return 1
      fi
      _wt_list
      ;;
    branch|pr)
      if (( $# > 2 )); then
        print -u2 -- "Usage: wt $1 [branch-or-pr-number]"
        return 1
      fi
      "_wt_$1" "${@:2}"
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
    create-from)
      if (( $# > 3 )); then
        print -u2 'Usage: wt create-from [base] [name]'
        return 1
      fi
      _wt_create_from "${@:2}"
      ;;
    remove)
      if (( $# > 2 )); then
        print -u2 'Usage: wt remove [worktree-path]'
        return 1
      fi
      _wt_remove "${@:2}"
      ;;
    *)
      print -u2 'Usage: wt [list | branch | pr | cd <worktree-path> | create <name> | create-from [base] [name] | remove [worktree-path]]'
      return 1
      ;;
  esac
}

_wt() {
  case $CURRENT in
    2)
      local -a commands=(
        'list:show Herdr worktrees'
        'branch:pick a local or remote branch to open in Herdr'
        'pr:pick an open pull request to open in Herdr'
        'cd:open a Herdr worktree workspace'
        'create:create a worktree from the current branch'
        'create-from:create a worktree from a chosen base branch'
        'remove:remove a clean Herdr worktree'
      )
      _describe 'wt command' commands
      ;;
    3)
      case ${words[2]} in
        branch|create-from)
          local kind branch
          local -a branches
          while IFS=$'\t' read -r kind branch; do
            branch=${branch//:/\\:}
            branches+=("$branch:$kind")
          done < <(_wt_branch_rows 2>/dev/null)
          _describe -V 'branch (local first)' branches
          ;;
        pr)
          local number branch title author
          local -a prs
          while IFS=$'\t' read -r number branch title author; do
            prs+=("$number:$title ($author, $branch)")
          done < <(_wt_pr_rows 2>/dev/null)
          _describe 'pull request' prs
          ;;
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
    4)
      [[ ${words[2]} == create-from ]] && _message 'new branch/worktree name'
      ;;
  esac
}

compdef _wt wt
