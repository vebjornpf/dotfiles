#!/usr/bin/env bash

set -euo pipefail

lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$lib_dir/env.sh"

state_dir="${JIRA_STATE_DIR:-$HOME/git/daily/jira}"
sync_script="$lib_dir/sync.sh"
project_metadata_file=""

usage() {
  cat <<'EOF'
Usage: jira create

Create a Jira work item interactively.
EOF
}

trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

pick_simple() {
  local prompt="$1"
  shift
  printf '%s\n' "$@" | fzf --prompt="$prompt > " --height=40% --layout=reverse
}

pick_from_tsv() {
  local file="$1"
  local prompt="$2"

  [[ -f "$file" ]] || return 1

  fzf --prompt="$prompt > " \
    --delimiter=$'\t' \
    --with-nth=1,2,3 \
    --height=60% \
    --layout=reverse < "$file"
}

prompt_required_line() {
  local label="$1"
  local value

  while true; do
    read -e -r -p "$label: " value
    value="$(trim "$value")"
    if [[ -n "$value" ]]; then
      printf '%s\n' "$value"
      return
    fi
    echo "$label is required" >&2
  done
}

edit_description_file() {
  local file="$1"
  local editor

  editor="${EDITOR:-vi}"
  "$editor" "$file" </dev/tty >/dev/tty 2>/dev/tty
}

ensure_picker_inputs() {
  mkdir -p "$state_dir"

  if [[ ! -f "$state_dir/epics-completion.tsv" || ! -f "$state_dir/all-completion.tsv" ]]; then
    bash "$sync_script" all >/dev/null
  fi
}

load_project_metadata() {
  project_metadata_file="$(mktemp)"
  trap "rm -f \"$project_metadata_file\"" EXIT
  acli jira project view --key "$JIRA_PROJECT_KEY" --json > "$project_metadata_file"
}

pick_issue_type() {
  jq -r '.issueTypes[]? | [.name, ((.subtask // false) | tostring), (.hierarchyLevel // 0)] | @tsv' "$project_metadata_file" \
    | fzf --prompt='Type > ' --delimiter=$'\t' --with-nth=1 --height=50% --layout=reverse
}

pick_priority() {
  pick_simple "Priority" Low Medium High
}

pick_story_epic() {
  local selected epic_key

  selected="$(pick_from_tsv "$state_dir/epics-completion.tsv" "Epic")" || return 1
  epic_key="${selected%%$'\t'*}"
  printf '%s\n' "$epic_key"
}

pick_subtask_parent() {
  local selected parent_key

  selected="$(pick_from_tsv "$state_dir/all-completion.tsv" "Parent task")" || return 1
  parent_key="${selected%%$'\t'*}"
  printf '%s\n' "$parent_key"
}

pick_component() {
  local components

  components="$({ printf 'none\n'; jq -r '.components[]?.name' "$project_metadata_file" | LC_ALL=C sort -fu; })"
  printf '%s\n' "$components" | fzf --prompt='Component > ' --height=60% --layout=reverse
}

build_create_payload() {
  local summary="$1"
  local description_file="$2"
  local issue_type="$3"
  local component="$4"
  local epic_key="$5"
  local priority="$6"
  local parent_issue_id="$7"
  local payload_file="$8"

  jq -n \
    --arg project_key "$JIRA_PROJECT_KEY" \
    --arg summary "$summary" \
    --arg issue_type "$issue_type" \
    --rawfile description_text "$description_file" \
    --arg component "$component" \
    --arg epic_key "$epic_key" \
    --arg priority "$priority" \
    --arg parent_issue_id "$parent_issue_id" \
    '
      {
        projectKey: $project_key,
        summary: $summary,
        type: $issue_type,
        description: {
          type: "doc",
          version: 1,
          content: (
            ($description_text | split("\n"))
            | if length == 0 then
                [{type: "paragraph", content: []}]
              else
                map({
                  type: "paragraph",
                  content: (if . == "" then [] else [{type: "text", text: .}] end)
                })
              end
          )
        }
      }
      | if $parent_issue_id != "" then
          .parentIssueId = $parent_issue_id
        else
          .
        end
      | .additionalAttributes = {}
      | if $component == "" or $component == "none" then
          .
        else
          .additionalAttributes.components = [
            {name: $component}
          ]
          | .
        end
      | if $epic_key != "" then
          .additionalAttributes.customfield_10006 = $epic_key
          | .
        else
          .
        end
      | if $priority != "" then
          .additionalAttributes.priority = {name: $priority}
          | .
        else
          .
        end
      | if (.additionalAttributes | length) == 0 then del(.additionalAttributes) else . end
    ' > "$payload_file"
}

create_issue() {
  local payload_file="$1"
  local -a cmd=(acli jira workitem create --from-json "$payload_file" --json)
  local output stderr_file key

  stderr_file="$(mktemp)"
  trap "rm -f \"$stderr_file\"" RETURN

  if ! output="$("${cmd[@]}" 2>"$stderr_file")"; then
    cat "$stderr_file" >&2
    return 1
  fi

  key="$(printf '%s\n' "$output" | jq -r '.key // .issues[0].key // empty')"
  if [[ -z "$key" ]]; then
    [[ -s "$stderr_file" ]] && cat "$stderr_file" >&2
    printf '%s\n' "$output" >&2
    return 1
  fi

  printf '%s\n' "$key"
}

assign_issue_to_me() {
  local key="$1"

  acli jira workitem assign --key "$key" --assignee @me --yes >/dev/null
}

ensure_backlog_status() {
  local key="$1"
  local status

  status="$(acli jira workitem view "$key" --fields status --json | jq -r '.fields.status.name // empty')"

  if [[ "$status" != "Backlog" ]]; then
    acli jira workitem transition --key "$key" --status Backlog --yes >/dev/null
  fi
}

main() {
  local title description_file issue_type_row issue_type issue_type_is_subtask issue_type_hierarchy epic_key parent_key parent_issue_id component priority assign_to_me payload_file issue_key

  case "${1:-}" in
    "" )
      ;;
    -h|--help|help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown jira create argument: $1" >&2
      echo >&2
      usage >&2
      exit 1
      ;;
  esac

  require_jira_project_key
  ensure_picker_inputs
  load_project_metadata

  title="$(prompt_required_line "Title")"

  description_file="$(mktemp)"
  payload_file="$(mktemp)"
  trap "rm -f \"$project_metadata_file\" \"$description_file\" \"$payload_file\"" EXIT

  edit_description_file "$description_file"

  issue_type_row="$(pick_issue_type)" || exit 1
  issue_type="${issue_type_row%%$'\t'*}"
  issue_type_row="${issue_type_row#*$'\t'}"
  issue_type_is_subtask="${issue_type_row%%$'\t'*}"
  issue_type_hierarchy="${issue_type_row#*$'\t'}"
  epic_key=""
  parent_key=""
  parent_issue_id=""

  if [[ "$issue_type_is_subtask" == "true" ]]; then
    parent_key="$(pick_subtask_parent)" || exit 1
    parent_issue_id="$parent_key"
  elif [[ "$issue_type_hierarchy" == "0" ]]; then
    epic_key="$(pick_story_epic)" || exit 1
  fi

  component="$(pick_component)" || exit 1
  priority="$(pick_priority)" || exit 1
  assign_to_me="$(pick_simple "Assign to me" yes no)" || exit 1

  build_create_payload "$title" "$description_file" "$issue_type" "$component" "$epic_key" "$priority" "$parent_issue_id" "$payload_file"
  issue_key="$(create_issue "$payload_file")" || exit 1

  if [[ "$assign_to_me" == "yes" ]]; then
    assign_issue_to_me "$issue_key"
  fi

  if [[ "$issue_type_is_subtask" != "true" ]]; then
    ensure_backlog_status "$issue_key"
  fi

  printf '%s\n' "$issue_key"
}

main "$@"
