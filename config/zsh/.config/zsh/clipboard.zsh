source "$HOME/.config/zsh/lib/clipboard.sh"

pwdcp() {
  local dir
  dir=$(pwd)

  if ! printf '%s' "$dir" | clipboard_copy; then
    return 1
  fi

  printf '%s\n' "$dir"
}
