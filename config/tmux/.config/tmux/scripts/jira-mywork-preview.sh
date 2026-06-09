#!/usr/bin/env bash

set -euo pipefail

status_file="$HOME/git/daily/jira/sync-status.json"
target="${1:-mywork}"
b64="${2:-}"

last_sync="Never"

if [[ -f "$status_file" ]]; then
  synced_at="$(jq -r --arg target "$target" '.targets[$target].last_sync_at // .last_sync_at // empty' "$status_file")"
  [[ -n "$synced_at" ]] && last_sync="$synced_at"
fi

if [[ -z "$b64" ]]; then
  printf 'last sync %s\n' "$last_sync"
  exit 0
fi

printf '%s' "$b64" | base64 --decode | jq -r --arg last_sync "$last_sync" '
  def repeat($s; $n):
    reduce range(0; $n) as $i (""; . + $s);

  def marks_text($node):
    reduce (($node.marks // []))[] as $mark ($node.text // "";
      if $mark.type == "link" then . + " <" + ($mark.attrs.href // "") + ">"
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
    "url       https://elhub.atlassian.net/browse/" + $issue.key,
    (
      if ($issue.fields.description? // null) == null then
        ""
      else
        "\nDescription\n" + (($issue.fields.description // {}) | render_description)
      end
    )
  ]
  | .[]
'
