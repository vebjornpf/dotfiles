daily() {
  local directory="$HOME/git/daily/notes/daily"
  mkdir -p "$directory" || return
  nvim "$directory/$(date +%F).md"
}
