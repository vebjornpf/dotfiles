#!/usr/bin/env sh

clipboard_copy() {
  if command -v pbcopy >/dev/null 2>&1; then
    pbcopy
  elif command -v clip.exe >/dev/null 2>&1; then
    clip.exe
  elif command -v wl-copy >/dev/null 2>&1; then
    wl-copy
  elif command -v xclip >/dev/null 2>&1; then
    xclip -selection clipboard
  else
    printf 'clipboard_copy: no clipboard tool found (pbcopy / clip.exe / wl-copy / xclip)\n' >&2
    return 1
  fi
}
