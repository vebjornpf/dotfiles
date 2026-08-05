source "$HOME/.config/zsh/lib/clipboard.sh"

cb() {
  if [ "$#" -eq 0 ]; then
    printf 'usage: cb <command> [args...]\n' >&2
    return 2
  fi

  "$@" | tee >(clipboard_copy)
  return ${pipestatus[1]}
}

pwdcp() {
  local dir
  dir=$(pwd)

  if ! printf '%s' "$dir" | clipboard_copy; then
    return 1
  fi

  printf '%s\n' "$dir"
}
