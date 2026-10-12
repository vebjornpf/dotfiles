# Basic status for the current branch, or another local branch.
gbs() {
  if (( $# > 1 )); then
    print -u2 'Usage: gbs [branch]'
    return 1
  fi
  local branch tracking repo prs field checkout main_checkout worktree type
  local upstream head number state url title
  local -aU heads pr_rows
  local -i lookup_failed=0
  git rev-parse --git-dir >/dev/null 2>&1 || {
    print -u2 'gbs: run inside a Git repository'
    return 1
  }
  branch=${1:-$(git branch --show-current)}
  if [[ -z $branch ]]; then
    print -u2 'gbs: detached HEAD; specify a local branch'
    return 1
  fi
  if ! git show-ref --verify --quiet "refs/heads/$branch"; then
    print -u2 -- "gbs: local branch not found: $branch"
    return 1
  fi
  tracking=$(git for-each-ref --format='%(upstream:short)' "refs/heads/$branch") || return

  if ! command -v gh >/dev/null 2>&1; then
    print -u2 'gbs: gh is required for repository and PR information'
    return 1
  fi
  repo=$(gh repo view --json nameWithOwner --jq .nameWithOwner) || return
  printf 'Repository: %s\n\nBranch\n  Name:     %s\n  Tracking: %s\n' \
    "$repo" "$branch" "${tracking:-not configured}"

  while IFS= read -r -d '' field; do
    case $field in
      'worktree '*)
        checkout=${field#worktree }
        [[ -n $main_checkout ]] || main_checkout=$checkout
        ;;
      "branch refs/heads/$branch") worktree=$checkout ;;
    esac
  done < <(git worktree list --porcelain -z)

  # The local branch may be renamed (e.g. pr-769); GitHub knows its upstream name.
  if [[ -n $tracking ]]; then
    upstream=$(git config --get "branch.$branch.merge")
    [[ $upstream == refs/heads/* ]] && heads+=("${upstream#refs/heads/}")
  fi
  heads+=("$branch")
  for head in "${heads[@]}"; do
    if prs=$(gh pr list --repo "$repo" --head "$head" --state all --limit 100 \
        --json number,state,url,title \
        --jq '.[] | [.number, .state, .url, .title] | @tsv'); then
      [[ -n $prs ]] && pr_rows+=("${(@f)prs}")
    else
      lookup_failed=1
    fi
  done
  if (( ! ${#pr_rows} )) && [[ $branch == pr-<-> ]]; then
    if prs=$(gh pr view "${branch#pr-}" --repo "$repo" \
        --json number,state,url,title \
        --jq '[.number, .state, .url, .title] | @tsv'); then
      [[ -n $prs ]] && pr_rows+=("$prs")
    else
      lookup_failed=1
    fi
  fi
  if (( ${#pr_rows} )); then
    print -r -- $'\nPull Requests'
    for prs in "${pr_rows[@]}"; do
      IFS=$'\t' read -r number state url title <<< "$prs"
      printf '  #%s  %s  %s\n        %s\n' "$number" "$state" "$url" "$title"
    done
    (( lookup_failed )) && print -r -- '  Some PR lookups failed.'
  elif (( lookup_failed )); then
    print -r -- $'\nPull Requests: lookup failed'
  else
    print -r -- $'\nPull Requests: none found'
  fi

  if [[ -n $worktree ]]; then
    type='Other worktree'
    if [[ $worktree == "$main_checkout" ]]; then
      type='Main checkout'
    elif [[ $worktree == "$HOME/.herdr/worktrees/"* ]]; then
      type='Herdr worktree'
    fi
    printf '\nWorktree\n  Status: checked out\n  Path:   %s\n  Type:   %s\n' "$worktree" "$type"
  else
    print -r -- $'\nWorktree: not checked out'
  fi
}
