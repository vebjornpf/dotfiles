# Git Aliases

# Status
alias gs='git status'

# Add
alias ga='git add'
alias gaa='git add .'
alias gap='git add -p'

# Commit
alias gc='git commit'
alias gcm='git commit -m'
alias gca='git commit --amend'
alias gcan='git commit --amend --no-edit'

# Push
alias gp='git push'
alias gpf='git push --force'

# Pull/Fetch
alias gf='git fetch'
alias gfa='git fetch --all'
alias gpl='git pull'
alias gpr='git pull --rebase'

# Rebase
alias grbi='git rebase -i'
alias grba='git rebase --abort'
alias grbc='git rebase --continue'

# Branch/Checkout
alias gb='git branch'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gcom='git checkout main'

# Stash
alias gst='git stash'
alias gsta='git stash apply'
alias gstp='git stash pop'
alias gsts='git stash show'

# Diff/Log
alias gd='git diff'
alias gds='git diff --staged'
alias gl='git log --oneline --graph'
alias glog='git log --oneline --decorate --graph --all'

# Reset/Clean
alias grs='git reset'
alias grsh='git reset --hard'
alias grhh='git reset HEAD --hard'
alias gclean='git clean -fd'

# Tag
alias gt='git tag'
alias gts='git tag -l'

# Cherry-pick/Revert/Amend
alias gcp='git cherry-pick'
alias grv='git revert' 

# GitHub
alias ghpr='gh pr view'
alias ghprc='gh pr create'
alias ghprms='gh pr merge --squash'
alias ghprm='gh pr merge -s -d --auto'


# Create a new Git worktree outside the current repo
gmkw() {
  set -e  # exit immediately if a command fails

  local branch="$1"
  local base_branch="${2:-main}"

  # Ensure we are inside a git worktree (not .git/)
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "❌ You must run this command from inside a Git worktree (not .git/)"
    return 1
  fi

  local repo_root
  repo_root=$(git rev-parse --show-toplevel)
  local repo_name
  repo_name=$(basename "$repo_root")
  local parent_dir
  parent_dir=$(dirname "$repo_root")
  local dir="${parent_dir}/${repo_name}-${branch}-wk"

  if [[ -z "$branch" ]]; then
    echo "Usage: mkworktree <branch-name> [base-branch]"
    return 1
  fi

  echo "🚀 Creating worktree '$branch' from '$base_branch'..."

  # Check if branch exists
  if ! git rev-parse --verify "$branch" >/dev/null 2>&1; then
    git worktree add -b "$branch" "$dir" "$base_branch"
  else
    git worktree add "$dir" "$branch"
  fi

  echo "✅ Worktree for '$branch' created at: $dir"

  # Move into the new directory
  cd "$dir" || return
}

gsf() {
  local branch
  branch=$(git branch --all --color=always | grep -v '/HEAD' | sed 's/^..//' | fzf --ansi --preview "git log --oneline --color=always --abbrev-commit --decorate --graph {}")
  branch=$(echo "$branch" | xargs)  # trim whitespace
  [[ -n "$branch" ]] && git switch "${branch#remotes/origin/}"
}

