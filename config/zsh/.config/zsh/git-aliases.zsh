# Git Aliases

# Status
alias gs='git status'

# Add
alias ga='git add'
alias gaa='git add .'
alias gap='git add -p'
alias gam='git add -u'

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
alias gplr='git pull --rebase'

# Rebase
alias grb='git rebase'
alias grbi='git rebase -i'
alias grbim='git rebase -i "$(git merge-base HEAD main)"'
alias grba='git rebase --abort'
alias grbc='git rebase --continue'

# Branch/Checkout
alias gb='git branch'
alias gbv='git branch -vv'
alias gco='git checkout'
alias gcob='git checkout -b'
alias gcom='git checkout main'

# Stash
alias gst='git stash'
alias gsta='git stash apply'
alias gstp='git stash pop'
alias gsts='git stash show'

# Diff/Log
alias gd='git diff'
alias gdm='nvim -c "DiffviewOpen main...HEAD"'
alias gds='git diff --staged'
alias gl='git log --oneline --graph'
alias glm='git log --oneline --decorate --graph --boundary main..HEAD'
alias glom='git log --oneline --decorate --graph --boundary origin/main..HEAD'
alias glf='git log --stat --decorate'
alias glog='git log --oneline --decorate --graph --all'
alias gsh='git show'

# Reset/Clean
alias grs='git reset'
alias grsh='git reset --hard'
alias grhh='git reset HEAD --hard'
alias gclean='git clean -fd'

# Tag
alias gt='git tag --sort=-version:refname'
alias gtl='git tag --sort=-version:refname | head -1'
alias gts='git tag -l'

# Cherry-pick/Revert/Amend
alias gcp='git cherry-pick'
alias grv='git revert' 

# GitHub
alias ghprc='gh pr create'
alias ghprw='gh pr create --base main --head "$(git branch --show-current)" --web'
alias ghprms='gh pr merge --squash'
alias ghprm='gh pr merge -s -d --auto'
alias gho='gh repo view --web'
alias ghob='gh browse --branch "$(git branch --show-current)"'
alias ghom='gh browse --branch main'

# Worktree
alias gwtr='git worktree remove'

# Clever way of switching between branhes
gfs() {
  git fetch --all --prune >/dev/null 2>&1
  local branch
  branch=$(git branch --color=always | grep -v '/HEAD' | sed 's/^..//' \
    | fzf --ansi \
          --header=$'enter: switch | alt-s: switch now | alt-d: delete | alt-b: create from selected' \
          --preview-window=up:75% \
          --bind "alt-d:execute(
            if [[ {} != 'main' && {} != 'master' ]]; then
              git branch -D {} >/dev/null 2>&1 && echo '🗑️  Deleted branch: {}' >&2
            else
              echo '⚠️  Cannot delete protected branch: {}' >&2
            fi
          )+reload(git branch --color=always | grep -v '/HEAD' | sed 's/^..//')" \
          --bind "alt-s:execute(git switch {} 2>&1)+reload(git branch --color=always | grep -v '/HEAD' | sed 's/^..//')" \
          --bind "alt-b:execute-silent(
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
            git log -3 --pretty=format:'%h | %cr | %s' \"\$b\" | fold -s -w \"${FZF_PREVIEW_COLUMNS:-80}\"
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
