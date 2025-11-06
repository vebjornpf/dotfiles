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
gri() {
  local target
  if [[ -z "$1" ]]; then
    target="HEAD^"
  elif [[ "$1" == <-> ]]; then
    target="HEAD~$1"
  else
    target="$1"
  fi

  git rebase -i "$target"
}

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

#gs() {
#  local branch
#  branch=$(git branch --all --color=always | grep -v '/HEAD' | sed 's/^..//' | fzf --ansi --preview "git log --oneline --color=always --abbrev-commit --decorate --graph {}")
#  branch=$(echo "$branch" | xargs)  # trim whitespace
#  [[ -n "$branch" ]] && git switch "${branch#remotes/origin/}"
#}

# Clever way of switching between branhes
gfs() {
  git fetch --all --prune >/dev/null 2>&1
  git update-ref refs/heads/main refs/remotes/origin/main
  local branch
  branch=$(git branch --color=always | grep -v '/HEAD' | sed 's/^..//' \
    | fzf --ansi \
          --preview-window=wrap \
          --bind "ctrl-d:execute(
            if [[ {} != 'main' && {} != 'master' ]]; then
              git branch -D {} >/dev/null 2>&1 && echo '🗑️  Deleted branch: {}' >&2
            else
              echo '⚠️  Cannot delete protected branch: {}' >&2
            fi
          )+reload(git branch --color=always | grep -v '/HEAD' | sed 's/^..//')" \
         --bind "ctrl-b:execute-silent(
           printf 'New branch name: ' > /dev/tty
           IFS= read -r new_branch < /dev/tty
           if [[ -n \$new_branch ]]; then
             {
               git switch {} >/dev/null 2>&1 &&
               git checkout -b \"\$new_branch\" >/dev/null 2>&1 &&
               echo '✅ Created and switched to branch: '\$new_branch >&2
             } || {
               echo '❌ Failed to create or switch branch: '\$new_branch > /dev/tty
             }
           fi
          )+abort" \
          --preview "
            b='{}'
            b_clean=\${b#remotes/origin/}

            echo '🪵 Last 3 commits:'
            # Show 3 latest commits, wrap dynamically to preview width, preserve newlines
            git log -3 --pretty=format:'%h | %cr | %s' \"\$b\" | fold -s -w \"\$(tput cols)\"
            echo
            echo

            echo '🕒 Days since last commit:'
            last_commit_date=\$(git log -1 --format=%ci \"\$b\" 2>/dev/null)
            if [[ -n \"\$last_commit_date\" ]]; then
              days=\$(( ( \$(date +%s) - \$(date -d \"\$last_commit_date\" +%s) ) / 86400 ))
              echo \"  \$days days ago\"
            else
              echo '  (no commits)'
            fi
            echo

            echo '🌿 Branch info:'
            tracking=\$(git for-each-ref --format='%(upstream:short)' \"refs/heads/\$b_clean\")
            if [[ -n \"\$tracking\" ]]; then
              echo \"  Tracking: \$tracking\"
              if git show-ref --verify --quiet \"refs/remotes/\$tracking\"; then
                echo '  ✅ Remote branch exists'
              else
                echo '  ⚠️ Remote branch no longer exists'
              fi
            else
              echo '  🚫 Not tracking a remote branch'
            fi
            echo

            echo '📊 Comparison to origin/main:'
            ahead=\$(git rev-list --count origin/main..\$b 2>/dev/null)
            behind=\$(git rev-list --count \$b..origin/main 2>/dev/null)
            echo \"  Ahead: \$ahead commits\"
            echo \"  Behind: \$behind commits\"
          ")

  branch=$(echo "$branch" | xargs)
  [[ -n "$branch" ]] && git switch "${branch#remotes/origin/}"
}



# Interactive PR browser: shows approvals and commits, lets you open or merge PRs
ghpr() {
  gh pr list --limit 50 --json number,title,reviewDecision \
    --template '{{range .}}{{printf "%-6.0f\t[%s]\t%s\n" .number .reviewDecision .title}}{{end}}' |
    column -t -s $'\t' |
    fzf --ansi --prompt="Select PR > " \
        --preview '
          gh pr view {1} --json title,author,reviewDecision,reviews,commits \
            --template "
Title: {{.title}}
Author: {{.author.login}}
Review decision: {{.reviewDecision}}

{{- range .reviews}}{{if eq .state \"APPROVED\"}}Approved by: {{.author.login}}
{{end}}{{end}}

Commits:
{{- range .commits}}
  {{- if .oid}}
  • {{slice .oid 0 7}}  {{.messageHeadline}}
  {{- else}}
  • (no hash)  {{.messageHeadline}}
  {{- end}}
{{- end}}
"' \
        --bind 'ctrl-w:execute-silent(gh pr view {1} --web)+abort' \
        --bind 'ctrl-m:execute-silent(
          gh pr merge {1} --squash --delete-branch --auto &&
          echo \"✅ Squash-merged PR {1}\" > /dev/tty
        )+abort'
}
