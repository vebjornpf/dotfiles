pwdcp() {
  local dir
  dir=$(pwd)

  if command -v xclip >/dev/null 2>&1; then
    printf '%s' "$dir" | xclip -selection clipboard
  else
    echo "xclip is not installed or not on PATH." >&2
    return 1
  fi

  printf '%s\n' "$dir"
}
