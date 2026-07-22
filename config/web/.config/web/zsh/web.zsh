export WEB_HOME="$HOME/.config/web"

# Optional local overrides: define WEB_LINK_ARGOCD_<ENV> entries here
# Supported variables:
#   WEB_LINK_ARGOCD_<ENV>   ArgoCD URL for a given environment name
[[ -f "$HOME/.config/local/tools.zsh" ]] && source "$HOME/.config/local/tools.zsh"

local web_bin_dir="$WEB_HOME/bin"

if [[ -d "$web_bin_dir" && ":$PATH:" != *":$web_bin_dir:"* ]]; then
  path=("$web_bin_dir" $path)
fi

_web() {
  local -a top_level argocd_envs
  top_level=(copilot codex argocd list)

  if (( CURRENT == 2 )); then
    compadd -- "${top_level[@]}"
    return
  fi

  case "${words[2]-}" in
    argocd)
      if (( CURRENT == 3 )); then
        # Derive env names from WEB_LINK_ARGOCD_* variables
        argocd_envs=()
        while IFS='=' read -r key _; do
          if [[ "$key" == WEB_LINK_ARGOCD_* ]]; then
            argocd_envs+=("$(echo "${key#WEB_LINK_ARGOCD_}" | tr '[:upper:]' '[:lower:]')")
          fi
        done < <(env | grep '^WEB_LINK_ARGOCD_')
        (( ${#argocd_envs[@]} > 0 )) && compadd -- "${argocd_envs[@]}"
      fi
      ;;
  esac
}

compdef _web web
