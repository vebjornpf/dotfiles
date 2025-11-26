# Skip if the shell is not interactive.
case $- in
  *i*) ;;
  *) return ;;
esac


# Safety: don't clobber files with ">"
set -o noclobber
setopt NO_BEEP
export PATH=/home/linuxbrew/.linuxbrew/bin:$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH
export EDITOR=nvim
export VISUAL=nvim
export JAVA_HOME="$HOME/.sdkman/candidates/java/17.0.14-tem"
alias n='nvim'

#export GCP_OAUTH_TOKEN="$(gcloud auth print-access-token 2>/dev/null)"

# Add git aliases

for f in "$ZDOTDIR"/*.zsh; do
  source "$f"
done

eval $(keychain --quiet --eval ~/.ssh/github)
