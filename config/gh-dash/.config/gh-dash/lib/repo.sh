repo_matches() {
  local path=$1
  local repo=$2
  local remote

  remote=$(git -C "$path" remote get-url origin 2>/dev/null || true)
  remote=${remote%.git}
  remote=${remote#git@github.com:}
  remote=${remote#ssh://git@github.com/}
  remote=${remote#https://github.com/}
  remote=${remote#http://github.com/}
  [[ "$remote" == "$repo" ]]
}

find_repo_clone() {
  local repo=$1
  local repo_name=${repo##*/}
  local candidate
  local -a candidates

  shopt -s nullglob
  candidates=("$HOME/git/$repo_name" "$HOME/git/$repo" "$HOME/git"/*/*)
  shopt -u nullglob

  for candidate in "${candidates[@]}"; do
    if [[ -e "$candidate" ]] && git -C "$candidate" rev-parse --git-dir >/dev/null 2>&1 && repo_matches "$candidate" "$repo"; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  printf 'no local clone of %s found under ~/git\n' "$repo" >&2
  return 1
}
