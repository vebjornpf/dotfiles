#!/usr/bin/env zsh

set -eu

root=${0:A:h:h}
test_dir=$(mktemp -d /tmp/opencode/ghpr-completion-test.XXXXXX)
trap 'rm -rf -- "$test_dir"' EXIT
mkdir "$test_dir/bin"

cat > "$test_dir/bin/gh" <<'SH'
#!/usr/bin/env bash
set -eu
case "$1 $2" in
  'repo view') printf 'example/repo\n' ;;
  'pr list')
    [[ "$*" == *headRefName* ]]
    cat <<'JSON'
[
  {"number":124,"title":"An older PR","author":{"login":"bob"},"url":"https://example.com/124","isDraft":true,"updatedAt":"2026-10-20T09:00:00Z","headRefName":"deps/update"},
  {"number":123,"title":"Fix authentication timeout with a very long title that must wrap","author":{"login":"alice"},"url":"https://example.com/123","isDraft":false,"updatedAt":"2026-10-21T10:00:00Z","headRefName":"fix/a-very-long-branch-name-without-spaces-for-wrapping"}
]
JSON
    ;;
  *) exit 1 ;;
esac
SH
chmod +x "$test_dir/bin/gh"
path=("$test_dir/bin" $path)

# Avoid loading personal local configuration or the interactive completion system.
compdef() { :; }
HOME="$test_dir" source "$root/config/ghpr/.config/ghpr/zsh/ghpr.zsh"
export GHPR_HOME="$root/config/ghpr/.config/ghpr"

fail() { print -u2 -r -- "FAIL: $*"; exit 1; }

local REPLY line
for width in 12 30 79; do
  _ghpr_completion_wrap 'Branch: fix/a-very-long-branch-name-without-spaces' "$width" '     '
  for line in "${(@f)REPLY}"; do
    (( ${(m)#line} <= width )) || fail "line exceeds $width columns: $line"
  done
done
_ghpr_completion_wrap 'Unicode: 日本語 café' 18 '     '
for line in "${(@f)REPLY}"; do
  (( ${(m)#line} <= 18 )) || fail 'Unicode display width'
done
print 'PASS: long words and Unicode wrap within the display width'

compadd() {
  [[ "$*" == '-l -V ghpr-pull-requests -d displays -- 123 124' ]] || fail "completion values: $*"
  [[ "${(j:,:)prs}" == '123,124' ]] || fail 'update ordering'
  [[ "$displays[1]" == '123  Fix authentication'* ]] || fail 'title'
  for field in 'Author: alice' 'State: open' 'Branch:' 'Updated: 2026-10-21'; do
    [[ "$displays[1]" == *"$field"* ]] || fail "missing $field"
  done
  [[ "$displays[2]" == *'State: draft'* ]] || fail 'draft state'
  [[ "$displays[2]" == *'Branch: deps/update'* ]] || fail 'source branch'
  for display in "${displays[@]}"; do
    for line in "${(@f)display}"; do
      (( ${(m)#line} < COLUMNS )) || fail "horizontal overflow: $line"
    done
  done
}

COLUMNS=40
CURRENT=3
words=(ghpr this '')
_ghpr
print 'PASS: stacked PR details and number-only completion'
CURRENT=4
words=(ghpr this checkout '')
_ghpr
print 'PASS: action-first completion'

rows=$(bash "$GHPR_HOME/lib/query.sh" this)
for line in "${(@f)rows}"; do
  fields=("${(@ps:\t:)line}")
  (( $#fields == 7 )) || fail 'existing query TSV contract changed'
  [[ "$fields[7]" == https://* ]] || fail 'existing URL field changed'
done
print 'PASS: other current-repo query consumers retain their seven fields'
