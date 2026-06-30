#!/usr/bin/env bash

SONAR_HOME="${SONAR_HOME:-$HOME/.config/sonar}"

[[ -f "$HOME/.config/local/sonar.zsh" ]] && source "$HOME/.config/local/sonar.zsh"

require_sonar_base_url() {
  if [[ -z "${SONAR_BASE_URL:-}" ]]; then
    echo "SONAR_BASE_URL is not set" >&2
    echo "Set it in ~/.config/local/sonar.zsh, for example:" >&2
    echo '  export SONAR_BASE_URL="https://sonar.example.com"' >&2
    exit 1
  fi
}

require_sonar_token() {
  if [[ -z "${SONAR_TOKEN:-}" ]]; then
    echo "SONAR_TOKEN is not set" >&2
    echo "Set it in ~/.config/local/sonar.zsh, for example:" >&2
    echo '  export SONAR_TOKEN="<token>"' >&2
    exit 1
  fi
}

open_url() {
  local url="$1"

  if command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$url" >/dev/null 2>&1 &
    return
  fi

  if command -v open >/dev/null 2>&1; then
    open "$url" >/dev/null 2>&1 &
    return
  fi

  echo "No browser opener found (expected xdg-open or open)" >&2
  exit 1
}

repo_root() {
  git rev-parse --show-toplevel 2>/dev/null
}

require_repo_root() {
  local root

  root="$(repo_root || true)"
  if [[ -z "$root" ]]; then
    echo "Run this command from inside a git repository" >&2
    exit 1
  fi

  printf '%s\n' "$root"
}

load_repo_config() {
  local root file line key value

  root="$(require_repo_root)"
  file="$root/.sonar/project"

  if [[ ! -f "$file" ]]; then
    echo "Missing repo config: $file" >&2
    echo "Create it with at least:" >&2
    echo '  mkdir -p .sonar' >&2
    echo '  cat > .sonar/project <<"EOF"' >&2
    echo '  projectKey=<sonar-project-key>' >&2
    echo '  branch=main' >&2
    echo '  EOF' >&2
    exit 1
  fi

  SONAR_REPO_ROOT="$root"
  SONAR_PROJECT_KEY=""
  SONAR_BRANCH="main"

  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    line="${line%$'\r'}"
    [[ -z "${line//[[:space:]]/}" ]] && continue
    key="${line%%=*}"
    value="${line#*=}"
    key="${key//[[:space:]]/}"
    value="${value#${value%%[![:space:]]*}}"
    value="${value%${value##*[![:space:]]}}"

    case "$key" in
      projectKey)
        SONAR_PROJECT_KEY="$value"
        ;;
      branch)
        SONAR_BRANCH="$value"
        ;;
    esac
  done <"$file"

  if [[ -z "$SONAR_PROJECT_KEY" ]]; then
    echo "projectKey is missing in $file" >&2
    exit 1
  fi
}

quality_names() {
  if (( $# == 0 )); then
    printf '%s\n' maintainability security reliability
    return
  fi

  local quality
  for quality in "$@"; do
    case "$quality" in
      all)
        printf '%s\n' maintainability security reliability
        ;;
      maintainability|security|reliability)
        printf '%s\n' "$quality"
        ;;
      *)
        echo "Unsupported quality: $quality" >&2
        exit 1
        ;;
    esac
  done | awk '!seen[$0]++'
}

quality_api_name() {
  case "$1" in
    maintainability) printf 'MAINTAINABILITY\n' ;;
    security) printf 'SECURITY\n' ;;
    reliability) printf 'RELIABILITY\n' ;;
    *)
      echo "Unsupported quality: $1" >&2
      exit 1
      ;;
  esac
}

quality_cache_file() {
  printf '%s/.sonar/raw/issues-%s.json\n' "$SONAR_REPO_ROOT" "$1"
}

quality_export_file() {
  printf '%s/.sonar/issues-%s.json\n' "$SONAR_REPO_ROOT" "$1"
}

sonar_project_web_url() {
  require_sonar_base_url
  load_repo_config
  printf '%s/dashboard?id=%s&branch=%s\n' "${SONAR_BASE_URL%/}" "$SONAR_PROJECT_KEY" "$SONAR_BRANCH"
}

rule_cache_file() {
  local rule_key="$1"
  local repository rule

  repository="${rule_key%%:*}"
  rule="${rule_key#*:}"
  printf '%s/.sonar/raw/rules/%s/%s.json\n' "$SONAR_REPO_ROOT" "$repository" "$rule"
}

ensure_parent_dir() {
  mkdir -p "$(dirname "$1")"
}

fetch_quality_to_cache() {
  local quality="$1"
  local api_quality page per_page issue_count total cache_file tmpdir page_file merged_file
  local -a page_files=()

  require_sonar_base_url
  require_sonar_token
  load_repo_config

  api_quality="$(quality_api_name "$quality")"
  cache_file="$(quality_cache_file "$quality")"
  ensure_parent_dir "$cache_file"

  tmpdir="$(mktemp -d)"
  trap "rm -rf -- '$tmpdir'" RETURN

  page=1
  per_page=500
  total=0
  issue_count=0

  while :; do
    page_file="$tmpdir/page-$page.json"
    curl -fsS -u "$SONAR_TOKEN:" \
      "$SONAR_BASE_URL/api/issues/search?componentKeys=$SONAR_PROJECT_KEY&branch=$SONAR_BRANCH&issueStatuses=OPEN,CONFIRMED&impactSoftwareQualities=$api_quality&ps=$per_page&p=$page" \
      >"$page_file"

    page_files+=("$page_file")
    total="$(jq '(.paging.total // .total // 0)' "$page_file")"
    issue_count=$((issue_count + $(jq '(.issues // []) | length' "$page_file")))

    if (( issue_count >= total )) || (( total == 0 )); then
      break
    fi

    page=$((page + 1))
  done

  merged_file="$tmpdir/merged.json"
  jq -s \
    --arg projectKey "$SONAR_PROJECT_KEY" \
    --arg branch "$SONAR_BRANCH" \
    --arg quality "$quality" \
    --arg fetchedAt "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    '
      {
        projectKey: $projectKey,
        branch: $branch,
        quality: $quality,
        fetchedAt: $fetchedAt,
        total: (if length == 0 then 0 else (.[0].paging.total // .[0].total // 0) end),
        effortTotal: (if length == 0 then 0 else (.[0].effortTotal // 0) end),
        issues: (map(.issues // []) | add),
        components: (map(.components // []) | add | unique_by(.key))
      }
    ' "${page_files[@]}" >"$merged_file"

  mv "$merged_file" "$cache_file"
  printf 'Synced %s: %s issues\n' "$quality" "$(jq '.total' "$cache_file")"
}

export_quality_from_cache() {
  local quality="$1"
  local cache_file export_file tmpfile

  load_repo_config

  cache_file="$(quality_cache_file "$quality")"
  export_file="$(quality_export_file "$quality")"

  if [[ ! -f "$cache_file" ]]; then
    echo "Missing cache file: $cache_file" >&2
    echo "Run 'sonar sync $quality' first" >&2
    exit 1
  fi

  ensure_parent_dir "$export_file"
  tmpfile="$(mktemp)"

  jq '
    {
      projectKey,
      branch,
      quality,
      fetchedAt,
      total,
      effortTotal,
      summary: {
        bySeverity: ([.issues[].severity] | group_by(.) | map({severity: .[0], count: length})),
        byImpactSeverity: ([.issues[].impacts[]?.severity] | group_by(.) | map({severity: .[0], count: length})),
        byRule: ([.issues[].rule] | group_by(.) | map({rule: .[0], count: length}) | sort_by(-.count, .rule)),
        byFile: ([.issues[].component] | group_by(.) | map({component: .[0], count: length}) | sort_by(-.count, .component))
      },
      issues: [
        .issues[]
        | {
            key,
            rule,
            severity,
            type,
            status,
            issueStatus,
            file: (.component | split(":")[1]),
            line,
            message,
            effort,
            debt,
            tags,
            author,
            creationDate,
            updateDate,
            cleanCodeAttribute,
            cleanCodeAttributeCategory,
            impacts
          }
      ]
    }
  ' "$cache_file" >"$tmpfile"

  mv "$tmpfile" "$export_file"
  printf 'Exported %s: %s\n' "$quality" "$export_file"
}

print_quality_status() {
  local quality="$1"
  local export_file

  load_repo_config

  export_file="$(quality_export_file "$quality")"
  if [[ ! -f "$export_file" ]]; then
    echo "$quality: missing export ($export_file)" >&2
    return 1
  fi

  jq -r --arg quality "$quality" '
    [
      $quality,
      (.total | tostring),
      (.effortTotal | tostring),
      ((.summary.byFile[0].component // "-") | split(":") | .[-1]),
      ((.summary.byRule[0].rule // "-"))
    ] | @tsv
  ' "$export_file"
}

sonar_sync() {
  local quality

  while IFS= read -r quality; do
    fetch_quality_to_cache "$quality"
    export_quality_from_cache "$quality"
  done < <(quality_names "$@")
}

sonar_export() {
  local quality

  while IFS= read -r quality; do
    export_quality_from_cache "$quality"
  done < <(quality_names "$@")
}

sonar_status() {
  local quality output=0

  printf 'quality\ttotal\teffortTotal\ttopFile\ttopRule\n'
  while IFS= read -r quality; do
    print_quality_status "$quality"
    output=1
  done < <(quality_names "$@")

  if (( output == 0 )); then
    echo "No qualities selected" >&2
    exit 1
  fi
}

sonar_path() {
  local quality

  load_repo_config

  while IFS= read -r quality; do
    printf '%s\tcache\t%s\n' "$quality" "$(quality_cache_file "$quality")"
    printf '%s\texport\t%s\n' "$quality" "$(quality_export_file "$quality")"
  done < <(quality_names "$@")
}

sonar_web() {
  open_url "$(sonar_project_web_url)"
}

fetch_rule_to_cache() {
  local rule_key="$1"
  local cache_file tmpfile

  require_sonar_base_url
  require_sonar_token
  load_repo_config

  cache_file="$(rule_cache_file "$rule_key")"
  ensure_parent_dir "$cache_file"
  tmpfile="$(mktemp)"

  curl -fsS -u "$SONAR_TOKEN:" \
    "$SONAR_BASE_URL/api/rules/show?key=$rule_key" \
    >"$tmpfile"

  mv "$tmpfile" "$cache_file"
  printf 'Fetched rule: %s\n' "$rule_key"
}

rule_keys_from_export() {
  local quality="$1"
  local export_file

  load_repo_config
  export_file="$(quality_export_file "$quality")"

  if [[ ! -f "$export_file" ]]; then
    echo "Missing export file: $export_file" >&2
    echo "Run 'sonar sync $quality' first" >&2
    exit 1
  fi

  jq -r '.issues[].rule' "$export_file"
}

sonar_rules() {
  local quality rule_key
  local -a rules=()

  while IFS= read -r quality; do
    while IFS= read -r rule_key; do
      [[ -n "$rule_key" ]] && rules+=("$rule_key")
    done < <(rule_keys_from_export "$quality")
  done < <(quality_names "$@")

  if (( ${#rules[@]} == 0 )); then
    echo "No rules found in exported issue files" >&2
    return 0
  fi

  while IFS= read -r rule_key; do
    fetch_rule_to_cache "$rule_key"
  done < <(printf '%s\n' "${rules[@]}" | awk '!seen[$0]++')
}
