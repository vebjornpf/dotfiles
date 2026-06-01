# Skip if the shell is not interactive.
case $- in
  *i*) ;;
  *) return ;;
esac

# Safety: don't clobber files with ">"
set -o noclobber
setopt NO_BEEP

# Homebrew — path differs between Linux and macOS
if [ -f /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"        # macOS (Apple Silicon)
elif [ -f /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"            # macOS (Intel)
elif [ -f /home/linuxbrew/.linuxbrew/bin/brew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"  # Linux
fi

export PATH="$HOME/.config/tmux/scripts:$HOME/.local/bin:$PATH"
export EDITOR=nvim
export VISUAL=nvim

alias n='nvim'

# Java via sdkman (manages JAVA_HOME itself)
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

#export GCP_OAUTH_TOKEN="$(gcloud auth print-access-token 2>/dev/null)"

# Source all zsh modules
for f in "$ZDOTDIR"/*.zsh; do
  source "$f"
done

# SSH agent via keychain (Linux / servers)
command -v keychain >/dev/null && eval "$(keychain --quiet --eval ~/.ssh/github)"
