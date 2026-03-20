repo="$1"
number="$2"
state="$3"

if [[ -z "$repo" || -z "$number" || -z "$state" ]]; then
  echo "Missing repo, PR number, or state" >&2
  exit 1
fi

if [[ "$state" == "DRAFT" ]]; then
  gh pr ready "$number" --repo "$repo"
else
  gh pr ready "$number" --repo "$repo" --undo
fi
