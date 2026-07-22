#!/usr/bin/env bash

set -euo pipefail

lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$lib_dir/env.sh"
source "$lib_dir/actions.sh"

create_project_key="TDX"
description_value=""
summary=""
component=""
priority=""
assign_to_me=0
POSITIONAL=()

usage() {
  cat <<'EOF'
Usage: jira create <EPIC-KEY> <Story|Spike|Bug> <Low|Medium|High> [options]

Create a Jira work item in project TDX.

Options:
  --summary <text>      Work item summary
  --component <name>    Jira component name
  --description <text>  Optional description text; otherwise $EDITOR opens at the end
  --assign              Assign created item to me
  -h, --help            Show this help

Examples:
  jira create TDX-123 Story High --summary "Investigate issue" --component api --assign
EOF
}

edit_description_file() {
  local file="$1"
  local editor

  editor="${EDITOR:-vi}"
  "$editor" "$file" </dev/tty >/dev/tty 2>/dev/tty
}

read_description() {
  local description_file

  description_file="$(mktemp)"
  trap 'rm -f "$description_file"' RETURN

  if [[ -n "$description_value" ]]; then
    printf '%s' "$description_value" > "$description_file"
  else
    edit_description_file "$description_file"
  fi

  cat "$description_file"
}

build_description_json() {
  local description_text="$1"

  jq -n --arg description_text "$description_text" '
    if $description_text == "" then
      null
    else
      {
        type: "doc",
        version: 1,
        content: (
          ($description_text | split("\n"))
          | map({
              type: "paragraph",
              content: (if . == "" then [] else [{type: "text", text: .}] end)
            })
        )
      }
    end
  '
}

build_create_payload() {
  local epic_key="$1"
  local issue_type="$2"
  local issue_priority="$3"
  local payload_file="$4"
  local description_text="$5"
  local description_json

  description_json="$(build_description_json "$description_text")"

  jq -n \
    --arg project_key "$create_project_key" \
    --arg summary "$summary" \
    --arg issue_type "$issue_type" \
    --arg component "$component" \
    --arg epic_key "$epic_key" \
    --arg issue_priority "$issue_priority" \
    --argjson description "$description_json" \
    '
      {
        projectKey: $project_key,
        summary: $summary,
        type: $issue_type,
        additionalAttributes: {
          components: [{name: $component}],
          customfield_10006: $epic_key,
          priority: {name: $issue_priority}
        }
      }
      | if $description == null then
          .
        else
          .description = $description
        end
    ' > "$payload_file"
}

create_issue() {
  local payload_file="$1"
  local epic_key="$2"
  local issue_type="$3"
  local issue_priority="$4"
  local description_text="$5"
  local -a cmd=(acli jira workitem create --from-json "$payload_file" --json)
  local output stderr_file key

  stderr_file="$(mktemp)"
  trap 'rm -f "$stderr_file"' RETURN

  if ! output="$("${cmd[@]}" 2>"$stderr_file")"; then
    printf 'Jira create failed\n' >&2
    printf 'Project: %s\n' "$create_project_key" >&2
    printf 'Epic: %s\n' "$epic_key" >&2
    printf 'Type: %s\n' "$issue_type" >&2
    printf 'Priority: %s\n' "$issue_priority" >&2
    printf 'Summary: %s\n' "$summary" >&2
    printf 'Component: %s\n' "$component" >&2
    printf 'Description:\n%s\n' "$description_text" >&2
    printf '\nPayload:\n' >&2
    cat "$payload_file" >&2
    printf '\nacli stderr:\n' >&2
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

ensure_backlog_status() {
  local key="$1"
  local status

  status="$(acli jira workitem view "$key" --fields status --json | jq -r '.fields.status.name // empty')"

  if [[ "$status" != "Backlog" ]]; then
    transition_issue_to_status "$key" Backlog
  fi
}

parse_args() {
  POSITIONAL=()

  while (( $# > 0 )); do
    case "$1" in
      -h|--help|help)
        usage
        exit 0
        ;;
      --summary)
        [[ $# -ge 2 ]] || { echo "Missing value for --summary" >&2; exit 1; }
        summary="$2"
        shift 2
        ;;
      --component)
        [[ $# -ge 2 ]] || { echo "Missing value for --component" >&2; exit 1; }
        component="$2"
        shift 2
        ;;
      --description)
        [[ $# -ge 2 ]] || { echo "Missing value for --description" >&2; exit 1; }
        description_value="$2"
        shift 2
        ;;
      --assign)
        assign_to_me=1
        shift
        ;;
      --*)
        echo "Unknown jira create option: $1" >&2
        usage >&2
        exit 1
        ;;
      *)
        POSITIONAL+=("$1")
        shift
        ;;
    esac
  done
}

validate_type() {
  case "$1" in
    Story|Spike|Bug)
      ;;
    *)
      echo "Unsupported work type: $1" >&2
      echo "Valid values: Story, Spike, Bug" >&2
      exit 1
      ;;
  esac
}

validate_priority() {
  case "$1" in
    Low|Medium|High)
      ;;
    *)
      echo "Unsupported priority: $1" >&2
      echo "Valid values: Low, Medium, High" >&2
      exit 1
      ;;
  esac
}

main() {
  local epic_key issue_type issue_priority payload_file issue_key description_text

  parse_args "$@"

  if (( ${#POSITIONAL[@]} != 3 )); then
    usage >&2
    exit 1
  fi

  epic_key="${POSITIONAL[0]:-}"
  issue_type="${POSITIONAL[1]:-}"
  issue_priority="${POSITIONAL[2]:-}"
  validate_type "$issue_type"
  validate_priority "$issue_priority"

  if [[ -z "$summary" ]]; then
    echo "Missing required option: --summary" >&2
    usage >&2
    exit 1
  fi

  if [[ -z "$component" ]]; then
    echo "Missing required option: --component" >&2
    usage >&2
    exit 1
  fi

  description_text="$(read_description)"
  payload_file="$(mktemp)"
  trap 'rm -f "$payload_file"' EXIT

  build_create_payload "$epic_key" "$issue_type" "$issue_priority" "$payload_file" "$description_text"
  issue_key="$(create_issue "$payload_file" "$epic_key" "$issue_type" "$issue_priority" "$description_text")" || exit 1
  if (( assign_to_me == 1 )); then
    assign_issue_to_me "$issue_key"
  fi
  ensure_backlog_status "$issue_key"

  printf '%s\n' "$issue_key"
}

main "$@"
