# AI command picker
# Picks from ~/.ai-commands.log (logged by opencode log_command tool)
# Log format: date | description | tool | command
# Uses print -z to put selected command into zsh prompt buffer

ai-cmd() {
  local log="$HOME/.ai-commands.log"

  if [[ ! -f "$log" ]]; then
    echo "No commands logged yet. Ask the AI to suggest some commands first."
    return 1
  fi

  local selected
  # Strip date before passing to fzf — show: description | tool | command
  selected=$(tac "$log" \
    | sed 's/^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\} | //' \
    | fzf \
      --prompt="ai-cmd> " \
      --height=40% \
      --layout=reverse \
      --preview='printf "%s\n" {} | fold -s -w "${FZF_PREVIEW_COLUMNS:-80}"' \
      --preview-window=down:3 \
      --no-sort) || return 0

  # Extract command — fields are: description | tool | command
  # Use awk to join everything from field 3 onward (preserves | inside commands)
  local command=$(echo "$selected" | awk -F' \\| ' '{for(i=3;i<=NF;i++) printf "%s%s",$i,(i<NF?" | ":""); print ""}')

  # Put into zsh prompt buffer — you can edit before hitting enter
  print -rz "$command"
}

# Ctrl+F: jump to next <placeholder> in buffer and remove it
_ai_cmd_next_placeholder() {
  if [[ "$BUFFER" != *'<'*'>'* ]]; then
    return
  fi

  local pre="${BUFFER%%<*}"
  local rest="${BUFFER#*<}"
  local post="${rest#*>}"

  BUFFER="${pre}${post}"
  CURSOR=${#pre}
}

zle -N _ai_cmd_next_placeholder
bindkey -M viins '^F' _ai_cmd_next_placeholder
bindkey -M vicmd '^F' _ai_cmd_next_placeholder
bindkey -M main '^F' _ai_cmd_next_placeholder
