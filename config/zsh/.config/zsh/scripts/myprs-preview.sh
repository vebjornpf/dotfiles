repo="$1"
number="$2"
state="$3"
title="$4"
updated="$5"
url="$6"
author="$7"
created="$8"
comments="$9"
locked="${10}"
labels="${11}"
body_b64="${12}"

if [[ -n "$body_b64" ]]; then
  body="$(printf '%s' "$body_b64" | base64 --decode 2>/dev/null)"
fi

wrap_width="${FZF_PREVIEW_COLUMNS:-80}"
if [[ "$wrap_width" -lt 20 ]]; then
  wrap_width=80
fi

state_color="$state"
if [[ "$state" == "DRAFT" ]]; then
  state_color=$'\033[33m'"$state"$'\033[0m'
elif [[ "$state" == "OPEN" ]]; then
  state_color=$'\033[32m'"$state"$'\033[0m'
fi

printf '\033[1m%s\033[0m\n' "$title"
printf '\033[2m%s#%s\033[0m\n\n' "$repo" "$number"
printf 'state    %b\n' "$state_color"
printf 'author   %s\n' "$author"
printf 'updated  %s\n' "$updated"
printf 'created  %s\n' "$created"
printf 'comments %s\n' "$comments"
printf 'locked   %s\n' "$locked"
printf 'labels   %s\n' "$labels"
printf 'url      %s\n' "$url"
printf '\n\033[36mBody\033[0m\n'
if [[ -n "$body" ]]; then
  printf '%s\n' "$body" | fold -s -w "$wrap_width"
else
  printf '\033[2m(no body)\033[0m\n'
fi
