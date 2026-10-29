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

local line expected='123,124'
compadd() {
  [[ "$*" == '-- list' ]] && return 0
  [[ "$*" == '-U -l -V ghpr-pull-requests -X '* ]] || fail "completion options: $*"
  [[ "${(j:,:)prs}" == "$expected" ]] || fail "completion values: ${(j:,:)prs}"
  [[ "$header" == 'NUMBER'*'AUTHOR'*'TITLE' ]] || fail 'column headers'
  for display in "${displays[@]}"; do
    [[ "$display" != *$'\n'* ]] || fail 'multiline row'
    [[ "$display" == '#123 '*'alice '*'Fix authentication'* || "$display" == '#124 '*'bob '*'An older PR' ]] || fail "row: $display"
  done
}

COLUMNS=40
CURRENT=3
words=(ghpr this '')
_ghpr
print 'PASS: table rows and number-only completion'
CURRENT=4
words=(ghpr this checkout '')
_ghpr
print 'PASS: action-first completion'

CURRENT=3
for search in alice ALICE authentication '#123' 123 'alice                Fix'; do
  PREFIX="$search"
  SUFFIX=''
  words=(ghpr this "$search")
  expected=123
  _ghpr
done
PREFIX=bob
expected=124
_ghpr
PREFIX=not-found
expected=''
_ghpr || true
PREFIX=''
print 'PASS: case-insensitive matching across number, author, and title'

rows=$(bash "$GHPR_HOME/lib/query.sh" this)
for line in "${(@f)rows}"; do
  fields=("${(@ps:\t:)line}")
  (( $#fields == 7 )) || fail 'existing query TSV contract changed'
  [[ "$fields[7]" == https://* ]] || fail 'existing URL field changed'
done
print 'PASS: other current-repo query consumers retain their seven fields'

listing=$(bash "$GHPR_HOME/bin/ghpr" this list)
[[ "$listing" == 'NUMBER'*'AUTHOR'*'TITLE'* ]] || fail 'list headers'
[[ "$listing" == *'#123'*'alice'*'Fix authentication timeout'* ]] || fail 'list number, author, and title'
[[ "$listing" == *'#124'*'bob'*'An older PR'* ]] || fail 'list includes drafts'
[[ "$listing" != *'https://'* ]] || fail 'list contains unwanted URL'
[[ "${${(f)listing}[2]}" == '#123'* ]] || fail 'list update ordering'
print 'PASS: current-repo list shows PR numbers, authors, and titles'
