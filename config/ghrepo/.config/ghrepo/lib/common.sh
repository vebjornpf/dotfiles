#!/usr/bin/env bash

set -euo pipefail

[[ -f "$HOME/.config/local/ghrepo.zsh" ]] && source "$HOME/.config/local/ghrepo.zsh"

ghrepo_state_dir() {
  printf '%s\n' "${GHREPO_STATE_DIR:-$HOME/git/daily/ghrepo}"
}

ghrepo_repos_file() {
  printf '%s/repos.tsv\n' "$(ghrepo_state_dir)"
}

ghrepo_git_root() {
  printf '%s\n' "${GHREPO_GIT_ROOT:-$HOME/git}"
}

repo_clone_dir_from_slug() {
  local repo_slug="$1"
  printf '%s/%s\n' "$(ghrepo_git_root)" "${repo_slug##*/}"
}

require_repos_file() {
  local repos_file
  repos_file="$(ghrepo_repos_file)"

  if [[ ! -f "$repos_file" ]]; then
    echo "repos.tsv not found: $repos_file" >&2
    echo "Run 'ghrepo sync' first." >&2
    exit 1
  fi
}

normalize_git_url() {
  local url="$1"
  url="${url%.git}"
  url="${url#git@github.com:}"
  url="${url#ssh://git@github.com/}"
  url="${url#https://github.com/}"
  url="${url#http://github.com/}"
  printf 'github.com/%s\n' "$url"
}

repo_slug_from_url() {
  local normalized
  normalized="$(normalize_git_url "$1")"
  printf '%s\n' "${normalized#github.com/}"
}

repo_clone_dir_from_url() {
  printf '%s/%s\n' "$(ghrepo_git_root)" "$(repo_slug_from_url "$1")"
}

ensure_repo_clone() {
  local repo_slug="$1"
  local git_root clone_dir

  git_root="$(ghrepo_git_root)"
  clone_dir="$(repo_clone_dir_from_slug "$repo_slug")"

  if [[ -d "$clone_dir/.git" ]]; then
    return 0
  fi

  mkdir -p "$git_root"

  (
    cd "$git_root"
    gh repo clone "$repo_slug"
  )
}

scan_local_repos() {
  local git_root
  git_root="$(ghrepo_git_root)"

  [[ -d "$git_root" ]] || return 0

  while IFS= read -r -d '' git_dir; do
    local repo_dir remote_url
    repo_dir="${git_dir%/.git}"
    remote_url="$(git -C "$repo_dir" remote get-url origin 2>/dev/null || true)"
    [[ -n "$remote_url" ]] || continue
    printf '%s\t%s\n' "$(normalize_git_url "$remote_url")" "$repo_dir"
  done < <(find "$git_root" -type d -name .git -print0 2>/dev/null)
}

open_url() {
  local url="$1"

  if command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$url" >/dev/null 2>&1 &
    return 0
  fi

  if command -v open >/dev/null 2>&1; then
    open "$url" >/dev/null 2>&1 &
    return 0
  fi

  echo "No browser opener found (expected xdg-open or open)" >&2
  return 1
}
