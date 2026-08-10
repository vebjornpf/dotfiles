#!/usr/bin/env bash

set -euo pipefail

lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$lib_dir/config.sh"

json=0
for argument in "$@"; do
  case "$argument" in
    --json) json=1 ;;
    -h|--help|help)
      printf 'Usage: jira doctor [--json]\n'
      exit 0
      ;;
    *)
      echo "Unknown jira doctor argument: $argument" >&2
      exit 1
      ;;
  esac
done

local_config="$HOME/.config/local/tools.zsh"
checks=()
values=()
add_check() {
  checks+=("$1")
  values+=("$2")
}

[[ -f "$local_config" ]] && add_check local_config ok || add_check local_config missing
for variable in JIRA_PROJECT_KEY JIRA_BASE_URL JIRA_ACCOUNT_ID; do
  [[ -n "${!variable:-}" ]] && add_check "$variable" ok || add_check "$variable" missing
done
for variable in JIRA_BOARD_URL ATLASSIAN_SITE ATLASSIAN_EMAIL ATLASSIAN_API_TOKEN; do
  [[ -n "${!variable:-}" ]] && add_check "$variable" ok || add_check "$variable" optional_missing
done
for command_name in acli jq fzf; do
  command -v "$command_name" >/dev/null 2>&1 && add_check "command:$command_name" ok || add_check "command:$command_name" missing
done
[[ -d "$JIRA_STATE_DIR" ]] && add_check state_dir ok || add_check state_dir missing
[[ -f "$JIRA_CACHE_FILE" ]] && add_check project_cache ok || add_check project_cache missing
for completion_file in team me backlog epics; do
  [[ -f "$JIRA_STATE_DIR/${completion_file}-completion.tsv" ]] \
    && add_check "${completion_file}_completion" ok \
    || add_check "${completion_file}_completion" missing
done

failed=0
for value in "${values[@]}"; do
  [[ "$value" == ok || "$value" == optional_missing ]] || failed=1
done

if (( json )); then
  {
    for (( i = 0; i < ${#checks[@]}; i++ )); do
      printf '%s\t%s\n' "${checks[i]}" "${values[i]}"
    done
  } | jq -Rn --argjson ok "$(( failed == 0 ? 1 : 0 ))" '
    [inputs | split("\t") | {(.[0]): .[1]}] | add as $checks
    | {ok: ($ok == 1), checks: $checks}
  '
else
  for (( i = 0; i < ${#checks[@]}; i++ )); do
    printf '%-24s %s\n' "${checks[i]}" "${values[i]}"
  done
  (( failed == 0 )) || echo "Fix the missing checks above. Run 'jira sync' after local config is ready." >&2
fi

exit "$failed"
