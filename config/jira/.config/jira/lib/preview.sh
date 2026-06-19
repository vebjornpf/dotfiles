#!/usr/bin/env bash

set -euo pipefail

lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$lib_dir/env.sh"

state_dir="${JIRA_STATE_DIR:-$HOME/git/daily/jira}"
target="${1:-mywork}"
b64="${2:-}"
wrap_width="${FZF_PREVIEW_COLUMNS:-80}"

require_jira_base_url

if [[ "$wrap_width" -lt 20 ]]; then
  wrap_width=80
fi

last_sync="$({
  case "$target" in
    mywork)
      jq -r '.last_synced_at // empty' "$state_dir/mywork-current.json" 2>/dev/null
      ;;
    backlog|epics)
      jq -r '.last_synced_at // empty' "$state_dir/all-current.json" 2>/dev/null
      ;;
    all)
      source_files=()
      [[ -f "$state_dir/all-current.json" ]] && source_files+=("$state_dir/all-current.json")
      [[ -f "$state_dir/mywork-current.json" ]] && source_files+=("$state_dir/mywork-current.json")
      if (( ${#source_files[@]} > 0 )); then
        jq -s -r '[.[].last_synced_at // empty] | map(select(length > 0)) | sort | last // empty' "${source_files[@]}" 2>/dev/null
      fi
      ;;
  esac
} || true)"

[[ -n "$last_sync" ]] || last_sync="Never"

if [[ -z "$b64" ]]; then
  printf 'last sync %s\n' "$last_sync"
  exit 0
fi

printf '%s' "$b64" | base64 --decode | jq -r --arg last_sync "$last_sync" --arg base_url "${JIRA_BASE_URL%/}" '
  def repeat($s; $n):
    reduce range(0; $n) as $i (""; . + $s);

  def marks_text($node):
    reduce (($node.marks // []))[] as $mark ($node.text // "";
      if $mark.type == "link" then
        . + (if ($mark.attrs.href // "") == "" then "" else "\n" + ($mark.attrs.href // "") end)
      elif $mark.type == "code" then "`" + . + "`"
      else .
      end
    );

  def inline_text:
    if type == "string" then .
    elif type == "array" then map(inline_text) | join("")
    elif type != "object" then ""
    elif .type == "text" then marks_text(.)
    elif .type == "hardBreak" then "\n"
    elif .type == "mention" then .attrs.text // .attrs.id // ""
    elif .type == "emoji" then .attrs.text // .attrs.shortName // ""
    elif .type == "inlineCard" then .attrs.url // ""
    elif .type == "status" then .attrs.text // ""
    else (.content // []) | map(inline_text) | join("")
    end;

  def blocks($indent; $ordered):
    if type == "array" then map(blocks($indent; $ordered)) | join("")
    elif type != "object" then ""
    elif .type == "doc" then (.content // []) | blocks($indent; $ordered)
    elif .type == "paragraph" then ((.content // []) | inline_text) + "\n"
    elif .type == "heading" then ((.content // []) | inline_text) + "\n"
    elif .type == "bulletList" then (.content // []) | map(blocks($indent; false)) | join("")
    elif .type == "orderedList" then (.content // []) | to_entries | map(.value | blocks($indent; .key + 1)) | join("")
    elif .type == "listItem" then
      ((if $ordered then ($ordered|tostring) + ". " else "- " end) as $prefix
      | ((.content // []) | map(blocks($indent + ($prefix | length); false)) | join("")) as $body
      | ($body | sub("\n$"; "") | split("\n")) as $lines
      | if ($lines | length) == 0 or ($lines[0] == "") then ""
        else
          ($prefix + $lines[0] + "\n")
          + (($lines[1:] | map(select(length > 0) | repeat(" "; $indent + ($prefix | length)) + . + "\n")) | join(""))
        end)
    elif .type == "codeBlock" then ((.content // []) | inline_text) + "\n"
    elif .type == "rule" then "---\n"
    elif .type == "blockquote" then ((.content // []) | blocks($indent; $ordered) | split("\n") | map(select(length > 0) | "> " + .) | join("\n")) + "\n"
    else ((.content // []) | map(blocks($indent; false)) | join(""))
    end;

  def render_description:
    (blocks(0; false)
      | gsub("\n{3,}"; "\n\n")
      | sub("\n+$"; ""));

  . as $issue |
  [
    "last sync " + $last_sync,
    "",
    ($issue.key + " " + ($issue.fields.summary // "")),
    "",
    "status    " + ($issue.fields.status.name // ""),
    "type      " + ($issue.fields.issuetype.name // ""),
    "priority  " + ($issue.fields.priority.name // ""),
    "assignee  " + ($issue.fields.assignee.displayName // "Unassigned"),
    "reporter  " + ($issue.fields.reporter.displayName // "Unknown"),
    "url       " + $base_url + "/browse/" + $issue.key,
    (
      if ($issue.fields.description? // null) == null then
        ""
      else
        "\nDescription\n" + (($issue.fields.description // {}) | render_description)
      end
    )
  ]
  | .[]
' | fold -s -w "$wrap_width"
