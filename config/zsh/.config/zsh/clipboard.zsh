pwdcp() {
  local dir
  dir=$(pwd)

  if command -v pbcopy >/dev/null 2>&1; then
    printf '%s' "$dir" | pbcopy           # macOS
  elif command -v wl-copy >/dev/null 2>&1; then
    printf '%s' "$dir" | wl-copy          # Linux Wayland
  elif command -v xclip >/dev/null 2>&1; then
    printf '%s' "$dir" | xclip -selection clipboard  # Linux X11
  else
    printf 'pwdcp: no clipboard tool found (pbcopy / wl-copy / xclip)\n' >&2
    return 1
  fi

  printf '%s\n' "$dir"
}
